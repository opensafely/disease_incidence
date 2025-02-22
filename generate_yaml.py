diseases = ["asthma", "copd", "chd", "stroke", "heart_failure", "dementia", "multiple_sclerosis", "epilepsy", "crohns_disease", "ulcerative_colitis", "dm_type2", "ckd", "psoriasis", "atopic_dermatitis", "osteoporosis", "rheumatoid", "depression", "coeliac", "pmr"]
# diseases = ["rheumatoid", "pmr"]

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

  generate_dataset_midpoint:
    run: ehrql:v1 generate-dataset analysis/dataset_definition_midpoint.py
      --output output/dataset_definition_midpoint.csv
    outputs:
      highly_sensitive:
        cohort: output/dataset_definition_midpoint.csv        

  # generate_dataset_data_avail:
  #   run: ehrql:v1 generate-dataset analysis/dataset_definition_data_avail.py
  #     --output output/dataset_definition_data_avail.csv
  #     #--
  #     #--diseases "{diseases}"
  #   outputs:
  #     highly_sensitive:
  #       cohort: output/dataset_definition_data_avail.csv

  # run_data_avail:
  #   run: stata-mp:latest analysis/101_data_availability.do
  #   needs: [generate_dataset_data_avail]
  #   outputs:
  #     moderately_sensitive:
  #       log1: logs/data_avail_tables.log   
  #       data1: output/tables/data_check_*.csv

  run_baseline_data_midpoint:
    run: stata-mp:latest analysis/000_baseline_data_midpoint.do
    needs: [generate_dataset_midpoint]
    outputs:
      moderately_sensitive:
        log1: logs/baseline_data_midpoint.log   
        table1: output/tables/reference_table_rounded.csv
        table2: output/tables/reference_mean_age_rounded.csv

  run_baseline_data:
    run: stata-mp:latest analysis/001_baseline_data.do
    needs: [generate_dataset]
    outputs:
      moderately_sensitive:
        log1: logs/baseline_data.log   
        table1: output/tables/baseline_table_rounded.csv
        table2: output/tables/table_mean_age_rounded.csv
        table3: output/tables/incidence_count_*.csv
        figure1: output/figures/count_inc_*.svg
"""

# Add diseases list to the header dynamically
#formatted_yaml_header = yaml_header.format(diseases=", ".join(diseases))

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
    intervals = 9 if year == 2024 else 12  # Set intervals conditionally
    for disease in diseases:
        yaml_body += yaml_template.format(disease=disease, year=year, intervals=intervals)
        all_needs.append(f"measures_dataset_{disease}_{year}")

needs_list = ", ".join(all_needs)

yaml_footer_template = f"""
  run_data_processing:
    run: stata-mp:latest analysis/002_processing_data.do
    needs: [generate_dataset, {needs_list}]
    outputs:
      moderately_sensitive:
        log1: logs/processing_data.log   
        table1: output/tables/redacted_counts_*.csv
        table2: output/tables/arima_standardised2.csv

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
generated_yaml = yaml_header + yaml_body + yaml_footer

# Save to a file
with open("project.yaml", "w") as file:
    file.write(generated_yaml)