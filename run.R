library(phonpack)
library(base64enc)
library(googlesheets)

# Get from BitBucket pipeline environment
BATCH_NO <- Sys.getenv("BITBUCKET_REPO_SLUG")
AUTH_STR <- Sys.getenv("GOOGLE_AUTH")

# Convert env variable to txt file, then to RDS file, then supply
# to gs_auth() as RDS file
base64_token <- tempfile()
decoded_rds  <- tempfile()
writeLines(text = AUTH_STR, con = base64_token)
base64decode(file = base64_token, output = decoded_rds)

auth_token  <- gs_auth(token = decoded_rds, cache = FALSE)
kdict_trans <- gs_title("kdict-transcriptions")

# Create new worksheet if not already present
if(!BATCH_NO %in% gs_ws_ls(kdict_trans)) {
    gs_ws_new(kdict_trans, ws_title = BATCH_NO)
    kdict_trans <- gs_title("kdict-transcriptions")
}

# List all TextGrids
list.files(
    path    = ".",
    pattern = ".TextGrid$",
    recursive = TRUE
) %>%

# Read 'ipa' tier from all listed TextGrids
map_df(function(tg_filename) {
    
    tg_filename %>%
    readTextGrid() %>%
    getTierByName("ipa") %>%
    getTierIntervals(discard_empty = TRUE) %>%
    mutate(source_file = tg_filename)        

}) %>% 

# Overwrite sheet with new data
gs_edit_cells(
    ss        = kdict_trans,
    ws        = BATCH_NO,
    input     = .,
    anchor    = "A1",
    col_names = TRUE,
    trim      = TRUE
)
