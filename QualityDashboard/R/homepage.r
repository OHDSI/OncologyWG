source("R/db_utilities.r")

create_homepage_html <- function()
{
  # All dataframes have a column partner. The indexes we write to the statements 
  # are the numeric columns in the united dataframe.
  sql <- paste0("with tmp as (
  select partner, sum(\"record_%\") as res
  from ", schema, ".standard_summary_report
  group by partner),
  partners as (
    select distinct partner
    from ", schema, ".patient
  )
  select partner, round((1 - coalesce(res, 0)) * 100, 2) as valid_standard
  from partners
  left join tmp using (partner)
  order by partner;")
  valid_standard <- sql_select(sql) # index 2
  
  sql <- paste0("with sums as (
    select partner, coalesce(sum(\"record_%\"), 0) as rec_perc, coalesce(sum(\"concept_%\"), 0) as con_perc
    from ", schema, ".standard_summary_report_cleaned
    group by partner
  ),
  ready as (
    select partner, round((1 - rec_perc) * 100, 2) as readiness_rec,
    round((1 - con_perc) * 100, 2) as readiness_con
    from sums
  )
  select partner, coalesce(readiness_rec, 100.00) as readiness_rec, coalesce(readiness_con, 100.00) as readiness_con
  from ", schema, ".patient
  left join ready using (partner)
  order by partner;")
  readiness <- sql_select(sql) # index 3, 4
  
  sql <- paste0("select partner, cnt as patient_count, to_char(coalesce(first_event, date('2000-01-01')), 'YYYY-MM-DD') as first_event,
  to_char(coalesce(last_event, date('2000-01-01')), 'YYYY-MM-DD') as last_event,
  to_char(coalesce(observation_start, date('2000-01-01')), 'YYYY-MM-DD') as observation_start,
  to_char(coalesce(observation_end, date('2000-01-01')), 'YYYY-MM-DD') as observation_end
  from ", schema, ".patient
  order by partner;")
  patient_data <- sql_select(sql) # index 5, 6, 7, 8, 9
  
  sql <- paste0("with wrongs as (
    select partner, \"record_%\" as wrong_mapping
    from ", schema, ".mapping_summary_report
    where critique = 'Wrong mapping'
  ),
  needs as (
    select partner, \"record_%\" as needs_mapping
    from ", schema, ".mapping_summary_report
    where critique = 'Needs mapping'
  ),
  avail as (
    select partner, \"record_%\" as available
    from ", schema, ".mapping_summary_report
    where critique = 'Mapping available'
  )
  select partner, round(coalesce(wrong_mapping, 0) * 100, 2) as wrong_mapping, 
  round(coalesce(needs_mapping, 0) * 100, 2) as needs_mapping, round(coalesce(available, 0) * 100, 2) as available
  from ", schema, ".patient
  left join wrongs using (partner)
  left join needs using (partner)
  left join avail using (partner)
  order by partner;")
  mapping_errors <- sql_select(sql) # index 10, 11, 12
  
  sql <- paste0("select partner, onelegged_perc, shallow_perc from ", schema, ".histo_topo_percent order by partner;")
  histo_topo <- sql_select(sql) # index 13, 14
  
  sql <- paste0("select * from ", schema, ".met_grade_stage order by partner;")
  met_grade_stage <- sql_select(sql) # index 15, 16, 17
  
  sql <- paste0("with cats as (
    select distinct partner, concept_class_id 
    from ", schema, ".genomic g 
    join ", cdm_schema, ".concept on g.standard=concept_id
    where concept_class_id <> 'Undefined'
  ),
  concatenated as (
    select partner, STRING_AGG(concept_class_id, ', ') as classes
    from cats
    group by partner
  )
  select partner, coalesce(classes, 'None') as genomic_classes
  from ", schema, ".patient
  left join concatenated using (partner)
  order by partner;")
  genomic_classes <- sql_select(sql) # index 18
  
  all_data <- merge(valid_standard, readiness, by = "partner")
  all_data <- merge(all_data, patient_data, by = "partner")
  all_data <- merge(all_data, mapping_errors, by = "partner")
  all_data <- merge(all_data, histo_topo, by = "partner")
  all_data <- merge(all_data, met_grade_stage, by = "partner")
  all_data <- merge(all_data, genomic_classes, by = "partner")
  
  rows = apply(all_data, 1, function(x) {
    num_valid <- as.numeric(x[2])
    color_valid <- ifelse(num_valid < 60, "red", ifelse(num_valid < 80, "yellow", "green"))
    ready_record <- as.numeric(x[3])
    ready_concept <- as.numeric(x[4])
    num_ready <- ifelse(ready_record < ready_concept, ready_record, ready_concept)
    color_ready <- ifelse(num_ready < 50, "red", ifelse(num_ready < 75, "yellow", "green"))
    lower_partner <- gsub(" ", "", tolower(x[1])) # create a lower-case key without spaces from partner name
    paste0("      <tr class=\"main-row\">\r\n",
           "        <td>", x[1], "</td>\r\n",
           "        <td>\r\n",
           "          <div class=\"progress-container\">\r\n",
           "            <div class=\"progress-fill progress-", color_valid, "\" style=\"width: ", num_valid, "%;\"></div>\r\n",
           "          </div>\r\n",
           "          <span>", num_valid, "%</span>\r\n",
           "        </td>\r\n",
           "        <td>\r\n",
           "          <div class=\"progress-container\">\r\n",
           "            <div class=\"progress-fill progress-", color_ready, "\" style=\"width: ", num_ready, "%;\"></div>\r\n",
           "          </div>\r\n",
           "          <span>", num_ready, "%</span>\r\n",
           "          <span class=\"more-info\" onclick=\"toggleRow('details_", lower_partner, "')\">More information</span>\r\n",
           "        </td>\r\n",
           "      </tr>\r\n",
           "      <tr id=\"details_", lower_partner, "\" class=\"hidden-row\">\r\n",
           "        <td colspan=\"3\">\r\n",
           "          <div class=\"data-overview\">\r\n",
           "            <strong>Patient count:</strong>", x[5], "\r\n",
           "            <br/><strong>Observation window:</strong>", x[8], " - ", x[9], "\r\n",
           "            <br/><strong>Data window:</strong>", x[6], " - ", x[7], "\r\n",
           "            <br/><strong>Readiness by records:</strong>", ready_record, "%\r\n",
           "            <br/><strong>Readiness by concepts:</strong>", ready_concept, "%\r\n",
           "            <br/><strong>Wrong mapping:</strong>", x[10], "%\r\n",
           "            <br/><strong>Needs mapping:</strong>", x[11], "%\r\n",
           "            <br/><strong>Mapping available:</strong>", x[12], "%\r\n",
           "            <br/><strong>One-legged cancer:</strong>", x[13], "%\r\n",
           "            <br/><strong>Shallow cancer:</strong>", x[14], "%\r\n",
           "            <br/><strong>Metastasis records:</strong>", x[15], "\r\n",
           "            <br/><strong>Stage records:</strong>", x[17], "\r\n",
           "            <br/><strong>Grade records:</strong>", x[16], "\r\n",
           "            <br/><strong>Genomic classes:</strong>", x[18], "\r\n",
           "          </div>\r\n        </td>\r\n      </tr>\r\n"
    )
  })
  
  p1_name <- "html/homepage_template_1.html"
  p2_name <- "html/homepage_template_2.html"
  part1 <- readChar(p1_name, file.info(p1_name)$size)
  part2 <- readChar(p2_name, file.info(p2_name)$size)
  result = paste0(part1, paste(rows, collapse = "\r\n"), part2)
  writeChar(result, paste0(target_dir, "hompage_table.html"), eos = NULL)
}

