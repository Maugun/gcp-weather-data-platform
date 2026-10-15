const DATAFORM_RUNNER_ACCOUNT_ID = "dataform-runner";
const WEATHER_FR_ANALYST_ACCOUNT_ID = "weather-fr-analyst";
const FRANCE_LOCATION_PREFIX = "FR";

function applyFranceAnalystRowAccess(tableName, projectId) {
  const dataformRunner = `serviceAccount:${DATAFORM_RUNNER_ACCOUNT_ID}@${projectId}.iam.gserviceaccount.com`;
  const franceAnalyst = `serviceAccount:${WEATHER_FR_ANALYST_ACCOUNT_ID}@${projectId}.iam.gserviceaccount.com`;

  return `
CREATE OR REPLACE ROW ACCESS POLICY dataform_runner_full_access
ON ${tableName}
GRANT TO ('${dataformRunner}')
FILTER USING (TRUE);

CREATE OR REPLACE ROW ACCESS POLICY weather_fr_analyst_france_filter
ON ${tableName}
GRANT TO ('${franceAnalyst}')
FILTER USING (location_id LIKE '${FRANCE_LOCATION_PREFIX}-%');

GRANT \`roles/bigquery.dataViewer\`
ON TABLE ${tableName}
TO "${franceAnalyst}";
`;
}

module.exports = { applyFranceAnalystRowAccess };
