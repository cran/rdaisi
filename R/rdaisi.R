#' Set the necessary environment variables to configure the Daisi client
#' @param python_path The path to the python binary on your system
#' @param daisi_instance The Daisi instance to connect to
#' @return TRUE if successful update has occurred
#'
#' @export
#'
#' @importFrom reticulate source_python
#'
#' @examples
#' \dontrun{
#' configure_daisi(python_path = "/usr/local/bin/python3", daisi_instance = "app")
#' }
configure_daisi <- function(python_path = NULL,
                            daisi_instance = "app") {
    if (!is.null(python_path)) {
        Sys.setenv(RETICULATE_PYTHON=python_path)
    }

    Sys.setenv("DAISI_BASE_URL" = paste0("https://", daisi_instance, ".daisi.io"))
    Sys.setenv("DAISI_BASE_ROUTE" = "/pebble-api/pebbles")
    Sys.setenv("DAISI_NEW_ROUTE" = "/pebble-api/daisies")

    return(TRUE)
}

#' Get the result of the Daisi Execution
#' @param daisi_execution The DaisiExecution object for which to fetch the result
#' @return The object produced by the given Daisi
#'
#' @importFrom httr GET content add_headers
#'
result_daisi <- function(daisi_execution) {
    r <- GET(
        paste0(daisi_execution$daisi$base_url, "/", daisi_execution$daisi$id, "/executions/", daisi_execution$id, "/results?download=true"),
               add_headers(c('Client'= 'pydaisi'))
    )

    result = content(r, "parsed")
    result <- daisi_execution$daisi$py_call$load_dill_string(result)

    return(result)
}

#' Begin execution of the given Daisi
#' @param daisi_execution The DaisiExecution object for which to fetch the result
#' @return The ID (in UUID format) of the execution
#'
#' @importFrom httr POST content
#'
execute_daisi <- function(daisi_execution) {
    r <- POST(
        paste0(daisi_execution$daisi$base_url, "/", daisi_execution$daisi$id, "/executions/", daisi_execution$endpoint),
        body = daisi_execution$parsed_args,
        encode = "json"
    )

    result = content(r, "parsed")

    return(result)
}

#' Initialize and connect to the given Daisi
#' @param daisi_id The name or UUID of the daisi
#' @param base_url The platform on which to access the daisi
#' @return daisi object with daisi information
#'
#' @export
#'
#' @importFrom httr GET content
#' @importFrom reticulate py_run_file
#'
#' @examples
#' \dontrun{
#' configure_daisi()
#'
#' d <- Daisi("Add Two Numbers")
#' d
#' }
Daisi <- function(daisi_id, base_url = NULL) {
    if (is.null(base_url)) {
        base_url <- Sys.getenv("DAISI_BASE_URL")
    }

    print(paste0("Looking for Daisi: ", daisi_id))
    print(paste0(base_url, Sys.getenv("DAISI_NEW_ROUTE"), "/connect?name=", gsub(" ", "%20", daisi_id)))
    r <- GET(paste0(base_url, Sys.getenv("DAISI_NEW_ROUTE"), "/connect?name=", gsub(" ", "%20", daisi_id)))
    result <- content(r, "parsed")

    daisi_obj <- list(
        id = result$id,
        base_url = paste0(base_url, Sys.getenv("DAISI_BASE_ROUTE")),
        name = result$name,
        endpoints = result$endpoints,
        py_call = py_run_file(system.file(file.path("python", "r_py_helpers.py"), package="rdaisi"))
    )

    class(daisi_obj) <- "daisi"

    endpoint_names <- sapply(daisi_obj$endpoints, function(x) x$name)

    all_functions <- lapply(endpoint_names, function(endpoint) {
        function(...) { DaisiExecution(daisi_obj,
                                    endpoint = eval(substitute(endpoint, env = parent.frame())),
                                    ...) }
    })
    names(all_functions) <- endpoint_names

    for (func in names(all_functions)) {
        daisi_obj[[func]] <- all_functions[[func]]
    }

    return(daisi_obj)
}

#' Generate a new execution of a given Daisi
#' @param daisi The Daisi object, initialized with Daisi()
#' @param endpoint The endpoint of the Daisi to call
#' @param ... Arguments passed onto the underlying Daisi
#'
#' @return DaisiExecution object with the Execution parameters
#'
#' @export
#'
#' @examples
#' \dontrun{
#' configure_daisi()
#'
#' d <- Daisi("Add Two Numbers")
#'
#' de <- DaisiExecution(d, list(firstNumber = 5, secondNumber = 6))
#'
#' Sys.sleep(1)
#'
#' de$value()
#' }
#'
DaisiExecution <- function(daisi, endpoint, ...) {
    daisi_exec_obj <- list(
        id = NULL,
        daisi = daisi,
        endpoint = endpoint,
        status = "STARTED",
        parsed_args = list(...)
    )

    daisi_exec_obj$id <- execute_daisi(daisi_exec_obj)
    daisi_exec_obj$value <- function() { result_daisi(daisi_exec_obj) }

    return(daisi_exec_obj)
}

#' Generate a new map execution of a given Daisi
#' @param daisi The Daisi object, initialized with Daisi()
#' @param args_list A list of named lists of arguments to provide to the Daisi
#' @return DaisiExecution object with the Execution parameters
#'
#' @export
#'
#' @examples
#' \dontrun{
#' configure_daisi()
#'
#' d <- Daisi("Add Two Numbers")
#'
#' bulk_options <- lapply(1:10, function(x) {
#'     list(firstNumber = x, secondNumber = 5)
#' })
#'
#' deb <- DaisiMapExecution(d, bulk_options)
#' deb
#' }
DaisiMapExecution <- function(daisi, args_list) {
    my_exec <- list()
    for (args in args_list) {
        de = DaisiExecution(daisi, args)

        my_exec[[length(my_exec) + 1]] <- de
    }

    return(my_exec)
}

