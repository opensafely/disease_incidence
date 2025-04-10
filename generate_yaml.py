diseases = ["asthma", "copd", "chd", "stroke", "heart_failure", "dementia", "multiple_sclerosis", "epilepsy", "crohns_disease", "ulcerative_colitis", "dm_type2", "ckd", "psoriasis", "atopic_dermatitis", "osteoporosis", "rheumatoid", "depression", "depression_broad", "coeliac", "pmr"]
# diseases = ["depression_broad"]

yaml_header = """
version: '3.0'

expectations:
  population_size: 1000

actions:
             
  generate_dataset:
    run: ehrql:v1 generate-dataset analysis/dataset_definition.py
      --output output/dataset_definition.csv
      #--
      #--diseases "{diseases}"
    outputs:
      highly_sensitive:
        cohort: output/dataset_definition.csv

  generate_dataset_demographics_disease:
    run: ehrql:v1 generate-dataset analysis/dataset_definition_demographics_disease.py
      --output output/dataset_definition_demographics_disease.csv
    outputs:
      highly_sensitive:
        cohort: output/dataset_definition_demographics_disease.csv        

  generate_dataset_data_avail:
    run: ehrql:v1 generate-dataset analysis/dataset_definition_data_avail.py
      --output output/dataset_definition_data_avail.csv
      #--
      #--diseases "{diseases}"
    outputs:
      highly_sensitive:
        cohort: output/dataset_definition_data_avail.csv

  run_data_avail:
    run: stata-mp:latest analysis/101_data_availability.do
    needs: [generate_dataset_data_avail]
    outputs:
      moderately_sensitive:
        log1: logs/data_avail_tables.log   
        data1: output/tables/data_check_*.csv
"""

yaml_demog = """
  generate_baseline_data_{year}:
    run: ehrql:v1 generate-dataset analysis/dataset_definition_demographics.py
      --output output/dataset_definition_{year}.csv
      --
      --start-date "{year}-04-01"
    outputs:
      highly_sensitive:
        cohort: output/dataset_definition_{year}.csv        
"""

yaml_prebody = ""
all_need = []

for year in range(2016, 2025):
    yaml_prebody += yaml_demog.format(year=year)
    all_need.append(f"generate_baseline_data_{year}")

need_list = ", ".join(all_need)


yaml_template = """
  measures_dataset_{disease}_{year}:
    run: ehrql:v1 generate-measures analysis/dataset_definition_measures.py
      --output output/measures/measures_dataset_{disease}_{year}.csv
      --
      --start-date "{year}-04-01"
      --intervals {intervals}
      --disease "{disease}"
    needs: [generate_dataset]
    outputs:
      highly_sensitive:
        measure_csv: output/measures/measures_dataset_{disease}_{year}.csv
"""

yaml_body = ""
all_needs = []

for year in range(2016, 2025):
    intervals = 8 if year == 2024 else 12  # Set intervals conditionally
    for disease in diseases:
        yaml_body += yaml_template.format(disease=disease, year=year, intervals=intervals)
        all_needs.append(f"measures_dataset_{disease}_{year}")

needs_list = ", ".join(all_needs)

yaml_footer_template = f"""
  run_baseline_data_reference:
    run: stata-mp:latest analysis/000_baseline_data_reference.do
    needs: [{need_list}]
    outputs:
      moderately_sensitive:
        log1: logs/baseline_data_reference.log   
        table1: output/tables/reference_table_rounded.csv

  run_baseline_data_reference_all:
    run: stata-mp:latest analysis/003_baseline_data_reference_all.do
    needs: [generate_dataset_demographics_disease]
    outputs:
      moderately_sensitive:
        log1: logs/baseline_data_reference_all.log   
        table1: output/tables/reference_table_rounded_all.csv       

  run_baseline_data_disease:
    run: stata-mp:latest analysis/001_baseline_data_disease.do
    needs: [generate_dataset_demographics_disease]
    outputs:
      moderately_sensitive:
        log1: logs/baseline_data_disease.log   
        table1: output/tables/baseline_table_rounded.csv
        table2: output/tables/incidence_count_*.csv
        figure1: output/figures/count_inc_*.svg      
  
  run_data_processing:
    run: stata-mp:latest analysis/002_processing_data.do
    needs: [generate_dataset, {needs_list}]
    outputs:
      moderately_sensitive:
        log1: logs/processing_data.log   
        table1: output/tables/redacted_counts_*.csv

  run_incidence_graphs:
    run: stata-mp:latest analysis/100_incidence_graphs.do
    needs: [run_data_processing]
    outputs:
      moderately_sensitive:
        log1: logs/descriptive_tables.log   
        figure1: output/figures/inc_comp_*.svg
        figure2: output/figures/prev_comp_*.svg
        figure3: output/figures/prev_adj_*.svg
        figure4: output/figures/inc_adj_*.svg
        figure5: output/figures/adj_sex_*.svg
        figure6: output/figures/unadj_age_*.svg
        figure7: output/figures/unadj_ethn_*.svg
        figure8: output/figures/unadj_imd_*.svg
        table1: output/tables/arima_standardised.csv

  run_sarima:
    run: r:latest analysis/200_sarima.R
    needs: [run_incidence_graphs]
    outputs:
      moderately_sensitive:
        log1: logs/sarima_log.txt   
        figure1: output/figures/raw_pre_covid_*.svg
        figure2: output/figures/differenced_pre_covid_*.svg
        figure3: output/figures/seasonal_pre_covid_*.svg
        figure4: output/figures/raw_acf_*.svg
        figure5: output/figures/differenced_acf_*.svg
        figure6: output/figures/seasonal_acf_*.svg
        figure7: output/figures/auto_residuals_*.svg
        figure8: output/figures/obs_pred_*.svg
        table1: output/tables/change_incidence_byyear.csv
        table2: output/tables/values_*.csv   
"""

yaml_footer = yaml_footer_template.format(needs_list=needs_list)

# Combine header, body, and footer
generated_yaml = yaml_header + yaml_prebody + yaml_body + yaml_footer

# Save to a file
with open("project.yaml", "w") as file:
    file.write(generated_yaml)