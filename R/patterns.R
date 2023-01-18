#' Recompose spells into a level/order below, down to level 2 for formula
#' @noRd
recompose_roles <- function(s) {

	# Validation, also can take more than one spell at a time
	validate_class(s, "spell")
	sl <- s

	for (i in seq_along(sl)) {
		t <- field(sl[i], "runes")[[1]]
		order <- decipher(t)
		p <- field(sl[i], "pattern")

		# roles
		rls <- roles(t)
		labs <- labels(t)
		outcome <- names(rls[rls == "outcome"])
		predictor <- names(rls[rls == "predictor"])
		exposure <- names(rls[rls == "exposure"])
		confounder <- names(rls[rls == "confounder"])
		mediator <- names(rls[rls == "mediator"])
		interaction <- names(rls[rls == "interaction"])
		strata <- names(rls[rls == "strata"])

		if (length(interaction) > 0 & length(exposure) > 0) {
			combined <-
				paste(rep(exposure, each = length(interaction)),
							interaction,
							sep = ":")
		} else {
			combined <- character()
		}

		covariates <- c(confounder, predictor, interaction, combined)

		#### Creating formulas one level down

		# Order = 2
		if (order == 2) {
			if (length(mediator) > 0 & length(outcome) == 0) {
				left <- mediator
				right <- setdiff(rhs(t), mediator)
			} else if (length(interaction) > 0) {
				left <- lhs(t)
				right <- c(exposure, covariates)
			} else {
				left <- lhs(t)
				right <- rhs(t)
			}

			if (p == "direct") {
				right <- paste0(right, collapse = " + ")
			}

			for (j in seq_along(left)) {
				for (k in seq_along(right)) {

					f <- paste0(left[j], " ~ ", right[k])
					if (length(strata) > 0) { for (l in seq_along(strata)) {
						mt <-
							match_runes(t, stats::formula(f)) |>
							c(get_runes(t, field = "runes", value = strata[l]))
						sl <- append(
							sl,
							new_spell(
								formula = f,
								runes = mt,
								pattern = p,
								order = decipher(mt)
							)
						)
					}} else {
						mt <- match_runes(t, stats::formula(f))
						p <- field(sl[i], "pattern")
						sl <- append(
							sl,
							new_spell(
								formula = f,
								runes = mt,
								pattern = p,
								order = decipher(mt)
							)
						)
					}
				}
			}
		}

		# Order = 3
		if (order == 3) {

			# Exposure on the right if outcome is present
			if (length(outcome) > 0) {
				for (j in seq_along(exposure)) {
					f <- paste0(
						outcome,
						" ~ ",
						paste(c(exposure[j], covariates), collapse = " + ")
					)
					if (length(strata) > 0) for (k in seq_along(strata)) {
						mt <-
							match_runes(t, stats::formula(f)) |>
							c(get_runes(t, field = "runes", value = strata[k]))
						p <- field(sl[i], "pattern")
						sl <- append(
							sl,
							new_spell(
								formula = f,
								runes = mt,
								pattern = p,
								order = decipher(mt)
							)
						)
					} else {
						mt <- match_runes(t, stats::formula(f))
						p <- field(sl[i], "pattern")
						sl <- append(
							sl,
							new_spell(
								formula = f,
								runes = mt,
								pattern = p,
								order = decipher(mt)
							)
						)
					}
				}
			}

			# mediation if present
			if (length(mediator) > 0) {
				for (j in 1:seq_along(mediator)) {
					# mediator on the right if outcome is available
					if (length(outcome) > 0) {
						f <- paste0(
							outcome,
							" ~ ",
							mediator[j]
						)
						if (length(strata) > 0) for (k in seq_along(strata)) {
							mt <-
								match_runes(t, stats::formula(f)) |>
								c(get_runes(t, field = "runes", value = strata[k]))
							p <- field(sl[i], "pattern")
							sl <- append(
								sl,
								new_spell(
									formula = f,
									runes = mt,
									pattern = p,
									order = decipher(mt)
								)
							)
						} else {
							mt <- match_runes(t, stats::formula(f))
							p <- field(sl[i], "pattern")
							sl <- append(
								sl,
								new_spell(
									formula = f,
									runes = mt,
									pattern = p,
									order = decipher(mt)
								)
							)
						}
					}

					# mediator on the left
					f <- paste0(
						mediator[j],
						" ~ ",
						paste(c(exposure, covariates), collapse = " + ")
					)
					# adding strata to the decomposition if needed
					if (length(strata) > 0) for (k in seq_along(strata)) {
						mt <-
							match_runes(t, stats::formula(f)) |>
							c(get_runes(t, field = "runes", value = strata[k]))
						p <- field(sl[i], "pattern")
						sl <- append(
							sl,
							new_spell(
								formula = f,
								runes = mt,
								pattern = p,
								order = decipher(mt)
							)
						)
					} else {
						mt <- match_runes(t, stats::formula(f))
						p <- field(sl[i], "pattern")
						sl <- append(
							sl,
							new_spell(
								formula = f,
								runes = mt,
								pattern = p,
								order = decipher(mt)
							)
						)
					}
				}
			}
		}

		# Order = 4
		if (order == 4) {
			for (j in seq_along(outcome)) {
				f <- paste0(
					outcome[j],
					" ~ ",
					paste(c(exposure, mediator, covariates), collapse = " + ")
				)
				mt <- match_runes(t, stats::formula(f))
				p <- field(sl[i], "pattern")
				sl <- append(
					sl,
					new_spell(
						formula = f,
						runes = mt,
						pattern = p,
						order = decipher(mt)
					)
				)
			}
		}
	}

	# Return spells, expected to have one level order less
	sl[field(sl, "order") > 0] |>
		unique()
}

#' Decompose and expand the patterns that affect the covariates of a spell
#' @noRd
decompose_patterns <- function(s) {

	# validation, also can take more than one spell at a time
	validate_class(s, "spell")

	# empty list for combinations for all combinations
	fl <- list()

	# handle the special case of the order being 4
	for (i in seq_along(s)) {

		if (field(s[i], "order") == 4) {
			fl <- append(fl, as.character(s[i]))
		}

	}

	# for everything else of lower order
	for (i in seq_along(s)) {

		t <- field(s[i], "runes")[[1]]
		vt <- vec_data(t)
		pattern <- field(s[i], "pattern")

		# roles
		rls <- roles(t)
		outcome <- names(rls[rls == "outcome"])
		predictor <- names(rls[rls == "predictor"])
		exposure <- names(rls[rls == "exposure"])
		confounder <- names(rls[rls == "confounder"])
		mediator <- names(rls[rls == "mediator"])
		interaction <- names(rls[rls == "interaction"])
		int_alone <- int_combined <- character() # for interaction terms

		if (length(interaction) > 0 & length(exposure) == 1) {
			int_alone <-
				paste(rep(exposure, each = length(interaction)),
							interaction,
							sep = ":")

			for (i in seq_along(interaction)) {
				int_term <-
					c(interaction[i], paste0(exposure, ":", interaction[i])) |>
					paste0(collapse = " + ")

				int_combined <- append(int_combined, int_term)
			}
		}

		# if no exposure variable, than can combine with interaction term

		# covariates and grouped variables that are not part of the main outcome and
		# exposure relationships must be separated out
		tier_list <- tiers(t)
		tier_lvls <- as.character(unique(tier_list))
		tier_vars <- character()
		for (i in seq_along(tier_lvls)) {
			tier_vars[i] <-
				tier_list[tier_list == tier_lvls[i]] |>
				names() |>
				paste(collapse = " + ")
		}

		covariates <-
			c(confounder, predictor, int_combined) |>
			{
				\(.x) .x[!(.x %in% names(tier_list))]
			}() |>
			c(tier_vars)

		# define left and right
		if (length(mediator) > 0) {
			left <- mediator
			right <- c(outcome, exposure)
		} else if (length(mediator) == 0) {
			left <- outcome
			right <- exposure
		}

		switch(pattern,
					 direct = {
					 	f <-
					 		c(right, covariates) |>
					 		paste(collapse = " + ") |>
					 		{
					 			\(.x) paste(left, .x, sep = " ~ ")
					 		}()

					 	fl <- append(fl, f)
					 },
					 sequential = {
					 	p <- ifelse(length(right) == 0 & length(covariates) > 0, 1, 0)
					 	for (n in p:length(covariates)) {

					 		right_side <-
					 			c(right, covariates[0:n]) |>
					 			paste0(collapse = " + ")

					 		if (right_side == "") {
					 			f <- list()
					 		} else {
					 			f <-
					 				c(right, covariates[0:n]) |>
					 				paste0(collapse = " + ") |>
					 				{
					 					\(.x) paste(left, .x, sep = " ~ ")
					 				}()
					 		}

					 		fl <- append(fl, f)
					 	}
					 },
					 parallel = {
					 	# modifier for covariates in mediation
					 	if (is.null(covariates)) {
					 		seq_covariates <- 1
					 	} else {
					 		seq_covariates <- seq_along(covariates)
					 	}

					 	for (n in seq_covariates) {
					 		f <-
					 			c(right, covariates[n]) |>
					 			paste0(collapse = " + ") |>
					 			{
					 				\(.x) paste(left, .x, sep = " ~ ")
					 			}()

					 		fl <- append(fl, f)
					 	}
					 },
					 fundamental = {
					 	all_right <- c(right, confounder, predictor, interaction, int_alone)
					 	for (j in seq_along(outcome)) {
					 		for (k in seq_along(all_right)) {
					 			f <- paste(outcome[j], all_right[k], sep = " ~ ")
					 			fl <- append(fl, f)
					 		}
					 	}
					 },
		)
	}

	# return
	unique(fl)
}

#' Identify order or complexity of a set of runes or formula
#' @noRd
decipher <- function(t) {
	validate_class(t, "rune")

	### order ###

	order <- integer()

	# zeroeth
	# only single term object

	# first
	# does not follow rules of roles
	# lhs = 1
	# rhs = 1
	# strata = 0

	# second
	# follows rules of roles
	# lhs = 1
	# rhs = exposure + confounder
	# rhs = mediator (no confounders allowed)
	# rhs =/= outcome
	# rhs = exposure + interaction + exposure:interaction
	# strata = 1
	# interaction >= 0

	# third
	# does not follow rules of roles
	# lhs = 1
	# rhs > 1 exposure
	# rhs > 1 mediator
	# rhs = exposure + mediator
	# strata > 1

	# fourth
	# lhs > 1

	rls <- roles(t)
	outcome <- names(rls[rls == "outcome"])
	predictor <- names(rls[rls == "predictor"])
	exposure <- names(rls[rls == "exposure"])
	confounder <- names(rls[rls == "confounder"])
	mediator <- names(rls[rls == "mediator"])
	interaction <- names(rls[rls == "interaction"])
	unknown <- names(rls[rls == "unknown"])
	strata <- names(rls[rls == "strata"])

	# number of variables
	out <- length(unique(outcome))
	exp <- length(exposure)
	prd <- length(c(confounder, predictor))
	med <- length(mediator)
	unk <- length(unknown)
	sta <- length(strata)
	int <- length(interaction)

	# number of left and right runes
	left <- sum(out)
	right <- sum(exp, prd, med, unk, int)
	n <- sum(left, right)

	# zeroeth order
	if (length(t) == 1) {
		order <- 0L
	}

	# first order
	if (n == 2) {
		order <- 1L
	}

	# second order
	if (length(t) >= 2 & sta <= 1) {
		if (out == 1 & any(exp) & med == 0) {
			order <- 2L
		}
		if (out == 0 & med == 1 & exp == 1) {
			order <- 2L
		}
		if (out == 1 & med == 1 & exp == 0 & prd == 0) {
			order <- 2L
		}
		if (out == 1 & prd > 1 & exp == 0 & med == 0) {
			order <- 2L
		}
		if (out == 1 & prd > 1 & exp == 1 & med == 0) {
			order <- 2L
		}
		if (sta == 1 & exp == 1) {
			order <- 2L
		}
		# drop the interaction term capacity if its only a second order formula
		if (int > 0 &  prd > 0 & out == 1) {
			order <- 2L
		}
	}

	# third order
	if (length(t) > 2) {
		if (all(out, exp, med)) {
			order <- 3L
		}
		if (exp > 1) {
			order <- 3L
		}
		if (med > 1) {
			order <- 3L
		}
		if (sta > 1) {
			order <- 3L
		}
	}

	# fourth order
	if (left > 1) {
		order <- 4L
	}

	# return
	order
}