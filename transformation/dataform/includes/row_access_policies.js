const DATAFORM_RUNNER_ACCOUNT_ID = "dataform-runner";
const FRANCE_LOCATION_PREFIX = "FR";

function applyWeatherRowAccess(tableName, projectId, allRowsReadersGroupEmail, frRowsReadersGroupEmail) {
  const dataformRunner = `serviceAccount:${DATAFORM_RUNNER_ACCOUNT_ID}@${projectId}.iam.gserviceaccount.com`;
  const allRowsReaders = `group:${allRowsReadersGroupEmail}`;
  const frRowsReaders = `group:${frRowsReadersGroupEmail}`;

  return `
CREATE OR REPLACE ROW ACCESS POLICY dataform_runner_full_access
ON ${tableName}
GRANT TO ('${dataformRunner}')
FILTER USING (TRUE);

CREATE OR REPLACE ROW ACCESS POLICY weather_all_rows_readers_full_access
ON ${tableName}
GRANT TO ('${allRowsReaders}')
FILTER USING (TRUE);

CREATE OR REPLACE ROW ACCESS POLICY weather_fr_rows_readers_france_filter
ON ${tableName}
GRANT TO ('${frRowsReaders}')
FILTER USING (location_id LIKE '${FRANCE_LOCATION_PREFIX}-%');

GRANT \`roles/bigquery.dataViewer\`
ON TABLE ${tableName}
TO "${allRowsReaders}";

GRANT \`roles/bigquery.dataViewer\`
ON TABLE ${tableName}
TO "${frRowsReaders}";
`;
}

module.exports = { applyWeatherRowAccess };
