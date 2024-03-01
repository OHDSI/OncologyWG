-- Insert into temporary table
DROP TABLE IF EXISTS @insertSchema.@queryTableName;

SELECT * INTO @insertSchema.@queryTableName
FROM (
  @queryText
)
