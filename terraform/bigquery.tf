resource "google_bigquery_dataset" "main_dataset" {
  dataset_id                  = "${var.dataset_name}_dataset"
  description                 = "Dataset for map ${var.dataset_name} project"
  location                    = "US"
}

resource "google_bigquery_table" "sequences" {
  dataset_id = google_bigquery_dataset.main_dataset.dataset_id
  table_id   = "sequences"
  deletion_protection = false

  schema = <<EOF
[
  {
    "name": "seq_name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "sequence name"
  },
  {
    "name": "seq_value",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "sequence value"
  }
]
EOF
}

resource "google_bigquery_table" "<table_name>" {
  dataset_id = google_bigquery_dataset.main_dataset.dataset_id
  table_id   = "<table_name>"
  deletion_protection = false

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "REQUIRED",
    "description": "project id used to identify the project"
  }, 
  {
    "name": "LAST_UPDATE_DATETIME",
    "type": "DATETIME",
    "mode": "REQUIRED",
    "description": "Last update datetime of code"
  }
]
EOF
}

resource "google_bigquery_routine" "get_row_id" {
  dataset_id      = google_bigquery_dataset.main_dataset.dataset_id
  routine_id      = "get_row_id"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  arguments {
    name = "sequence_name"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  } 
  definition_body = <<-EOS
    DECLARE seq_value int64;

    set seq_value = (SELECT seq_value FROM `<DATASET_NAME>_dataset.sequences` WHERE seq_name = sequence_name);
    
    IF seq_value IS NULL THEN
      INSERT INTO `<DATASET_NAME>_dataset.sequences` (seq_name, seq_value) VALUES (sequence_name, 1);
    ELSE
      UPDATE `<DATASET_NAME>_dataset.sequences` SET seq_value = seq_value + 1 WHERE seq_name = sequence_name;
    END IF;

    SELECT seq_value FROM `<DATASET_NAME>_dataset.sequences` WHERE seq_name = sequence_name;
  EOS
}
