-- number 1
SELECT
	provider_id
	,unnest(string_to_array(state_of_licenses, ', ' )) AS state_of_license
FROM talkspace.providers

-- number 2

SELECT *
FROM crosstab
(
	'WITH w AS
		(
			SELECT
				provider_id,
				unnest(string_to_array(state_of_licenses, ''/ '' )) AS state_of_license
			FROM talkspace.providers 
			ORDER BY 1
		)
	SELECT  
		w.state_of_license
		, w1.state_of_license
		, count(w.provider_id)
	FROM w
	LEFT JOIN w as w1
	ON w.provider_id = w1.provider_id
	GROUP BY 1,2
	ORDER BY 1'
	, 'VALUES(''CA''), (''DL''), (''FL''), (''NY''), (''TX'')'
)

	AS(state_of_license text, "CA" bigint, "DL" bigint, "FL" bigint, "NY" bigint, "TX" bigint)

-- number 3 - I used a python script to sum the diagonals and subtract the largest nondiagonal column value (Excluding the first column). I realize that this is not a complete solution and there are edgecases where this will not work, but I think I was on the right track.
# Define the matrix
matrix = [[3, 0, 2, 2, 0],
          [0, 2, 0, 0, 0],
          [2, 0, 2, 1, 0],
          [2, 0, 1, 2, 0],
          [0, 0, 0, 0, 2]]

# Step 1: Sum the diagonals
diagonal_sum = sum(matrix[i][i] for i in range(len(matrix)))

# Step 2: Identify the largest non-diagonal value in each column (excluding the first column)
largest_non_diagonal_values = []
for j in range(1, len(matrix)):
    column_values = [matrix[i][j] for i in range(len(matrix)) if i != j]  # Exclude the diagonal element
    if column_values:
        largest_value = max(column_values)
        largest_non_diagonal_values.append(largest_value)
    else:
        largest_non_diagonal_values.append(0)  # If the column is empty, set the largest value to 0

# Step 3: Sum the largest non-diagonal values
sum_largest_non_diagonal_values = sum(largest_non_diagonal_values)

# Step 4: Subtract the sum of the largest non-diagonal values from the sum of the diagonals
result = diagonal_sum - sum_largest_non_diagonal_values

# Print the result
print("Result:", result)

-- number 4 - assume that they can take have equal number of clients per state
WITH 
	p AS 
		(
			SELECT
				provider_id
				,UNNEST(string_to_array(state_of_licenses, ', ' )) AS state_of_license
			FROM talkspace.providers 
			ORDER BY 1
		)
	,
	m AS 
		(
			SELECT 
				id
				, max_client_capacity provider_capcity
				, COUNT(DISTINCT state_of_license) num_states
				, max_client_capacity/COUNT(DISTINCT state_of_license) num_clients_per_state
			FROM talkspace.max_client m
			LEFT JOIN p
			ON m.id = p.provider_id
			GROUP BY 1,2
		)
		
SELECT 
	state_of_license
	, SUM(num_clients_per_state) AS max_clients
FROM p
LEFT JOIN m
ON m.id = p.provider_id
GROUP BY 1

-- number 5 - Determine the number of providers, determin the number of current providers needed based on projections, find the difference

SELECT
	state
	, (projected_number_of_clients/current_avg_max_provider_capacity) - current_number_of_clients/current_avg_max_provider_capacity as additional_providers
FROM talkspace.state_fact sf 

-- number 6. Determine the number of current providers, determin the number of providers needed in 1 year using gorwth formula for client growth, find the difference. At the end of a year we will have to add about 1 provider in each state
WITH g AS
(
	SELECT 
		* 
		, CASE
			WHEN state = 'NY' THEN .01
			WHEN state = 'CA' THEN .02
			WHEN state = 'FL' THEN .02
			WHEN state = 'DL' THEN .03
			WHEN state = 'TX' THEN .01
				END AS growth_rate
	FROM talkspace.state_fact
)
SELECT 
	state
	, current_number_of_clients
	, current_avg_max_provider_capacity
	, growth_rate
	, ceiling(current_number_of_clients*((1 + growth_rate/12))^12) as projected_number_of_clients
	, ceiling(current_number_of_clients*((1 + growth_rate/12))^12/current_avg_max_provider_capacity - (current_number_of_clients/current_avg_max_provider_capacity)) as additional_providers
FROM g
	
