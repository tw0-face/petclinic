# https://github.com/blimpup/gitops-minicamp-2024-tf/blob/main/policies/gcp/compute-instance.rego
package main

max_monthly_cost := 10.00 # Set monthly cost limit

deny[msg] {
	project := input.projects[_]
	monthly_cost := to_number(project.breakdown.totalMonthlyCost)
	monthly_cost > max_monthly_cost
	msg := sprintf("Project %v exceeds the monthly spending limit. Monthly cost: %v, Limit: %v", [project.name, monthly_cost, max_monthly_cost])
}