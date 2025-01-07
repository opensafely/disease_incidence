#diseases = ["asthma", "copd", "chd", "stroke", "heart_failure", "dementia", "multiple_sclerosis", "epilepsy", "crohns_disease", "ulcerative_colitis", "dm_type2", "dm_type1", "ckd", "psoriasis", "atopic_dermatitis", "osteoporosis", "hiv", "depression", "coeliac", "pmr"]
diseases = ["copd", "chd"]

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
"""

# Add diseases list to the header dynamically
#formatted_yaml_header = yaml_header.format(diseases=", ".join(diseases))

yaml_template = """
  measures_dataset_{disease}:
    run: ehrql:v1 generate-measures analysis/dataset_definition_measures.py
      --output output/measures/measures_dataset_{disease}.csv
      --
      --start-date "2016-04-01"
      --intervals 102
      --intervals_years 8
      --disease "{disease}"
    needs: [generate_dataset]
    outputs:
      highly_sensitive:
        measure_csv: output/measures/measures_dataset_{disease}.csv
"""

# Generate disease list for incidence_graphs function
needs_list = ", ".join([f"measures_dataset_{disease}" for disease in diseases])

yaml_footer = f"""
  run_incidence_graphs:
    run: stata-mp:latest analysis/100_incidence_graphs.do
    needs: [generate_dataset, {needs_list}]
    outputs:
      moderately_sensitive:
        log1: logs/descriptive_tables.log   
        figure1: output/figures/incidence_*.svg
        figure2: output/figures/prevalence_*.svg
        figure3: output/figures/inc_comp_*.svg
        figure4: output/figures/prev_comp_*.svg
        figure5: output/figures/inc_adj_*.svg
        figure6: output/figures/inc_ma_sex_*.svg
        figure7: output/figures/prev_adj_*.svg
        figure8: output/figures/inc_adj_ma_*.svg
        figure9: output/figures/inc_adj_ma2_*.svg
        figure10: output/figures/adj_ma_sex_*.svg
        figure11: output/figures/adj_ma_sex2_*.svg
        figure12: output/figures/adj_ma_age_*.svg
        figure13: output/figures/adj_ma_age2_*.svg
        data1: output/data/arima_nonstandardised.csv

  run_sarima:
    run: r:latest analysis/200_sarima.R
    needs: [run_incidence_graphs]
    outputs:
      moderately_sensitive:
        log1: logs/sarima_log.txt   
        figure1: output/figures/observed_*.svg
        figure2: output/figures/raw_pre_covid_*.svg
        figure3: output/figures/differenced_pre_covid_*.svg
        figure4: output/figures/seasonal_pre_covid_*.svg
        figure5: output/figures/raw_acf_*.svg
        figure6: output/figures/differenced_acf_*.svg
        figure7: output/figures/seasonal_acf_*.svg
        figure8: output/figures/auto_residuals_*.svg
        figure9: output/figures/obs_pred_*.svg
        table1: output/tables/change_incidence_byyear.csv
        table2: output/tables/values_*.csv   
"""

#generated_yaml = formatted_yaml_header + "\n".join([yaml_template.format(disease=disease) for disease in diseases]) + yaml_footer
generated_yaml = yaml_header + "\n".join([yaml_template.format(disease=disease) for disease in diseases]) + yaml_footer

# Save to a file or print
with open("project.yaml", "w") as file:
    file.write(generated_yaml)