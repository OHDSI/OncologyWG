INSERT INTO @insertSchema.onc_validation_results (analysis_id, stratum_1, stratum_2, stratum_3, stratum_4, stratum_5, count_value)
SELECT * FROM (
  @analysisText
)