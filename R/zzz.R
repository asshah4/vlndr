# nocov start

.onLoad <- function(libname, pkgname) {
	if (!exists("possible_tidy")) {
		possible_tidy <-
			purrr::possibly(my_tidy, otherwise = NA, quiet = FALSE)
	}
	if (!exists("possible_parsnip_fit")) {
		possible_parsnip_fit <-
			purrr::possibly(my_parsnip_fit, otherwise = NA, quiet = FALSE)
	}
}

# nocov end