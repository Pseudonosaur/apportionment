--[[Set up array of states and populations from
    external file of census data.]]
dofile("census_data.lua")
available_seats = 435
totalpop = 0
for _, v in pairs(census_data) do
	totalpop = totalpop + v.pop
end

--standard denominator
sd = totalpop/available_seats

--[[ Assigns quotas to each state. Can be standard or modified
     quota, depending on denominator input ]]
function assign_quotas(denom, array)
	for _, v in pairs(array) do
		v.quota = v.pop/denom
	end
end

-- Assign standard quota
assign_quotas(sd, census_data)

function sumseats(array) --[[Sum the seats. Returns number of
                             seats filled.]]
	local sum = 0
	for _, v in pairs(array) do
		sum = sum + v.seats
	end
	return sum
end

-- Boolean. Determines if exactly 435 seats are filled.
function full_seating(array)
	if sumseats(array) == available_seats then
		return true
	else
		return false
	end
end
--[[ Assigns seats to each states based on lower quota Used in
     other methods of apportionment ]]
function assign_lq(array) --assign lower quota
	for _, v in pairs(array) do
		v.seats = math.floor(v.quota)
	end
end
--[[ Calculates percent error of a method, checking percent representation
     against actual percent population ]]
function percent_error(array)
	local total_error = 0
	local length = 0
	for _, v in pairs(array) do
		local percent_pop = v.pop/totalpop
		local percent_rep = v.seats/available_seats
		local percent_error = math.abs((percent_pop - percent_rep)/percent_pop)
		total_error = total_error + percent_error
		length = length + 1
	end
	return (total_error/length)*100
end

function hamilton_vinton(master_array)    
	local hv_list = master_array --leave the master list untouched.
			
			assign_lq(hv_list)
	
	-- Add seats to highest remainder states until all seats are filled
	while full_seating(hv_list) == false do
		local big_index = 1
		for _, v in pairs(hv_list) do
			if (v.quota - v.seats) > (hv_list[big_index].quota - hv_list[big_index].seats) then
				big_index = _
			end
		end
		hv_list[big_index].seats = hv_list[big_index].seats + 1
	end
	
	if full_seating(hv_list) == false then print("Hamilton-Vinton failed") end
	return hv_list
end

function jefferson(master_array)
	local j_list = master_array  --leave the master list untouched.
			
			assign_lq(j_list)
	
	local md = sd --modified divisor
	while full_seating(j_list) == false do
		if sumseats(j_list) > available_seats then
			md = md + 1
		else
			md = md - 1
		end
		assign_quotas(md, j_list)
		assign_lq(j_list)
	end
	
	if full_seating(j_list) == false then print("Jefferson failed") end
	return j_list
end

function adams(master_array)
	local a_list = master_array
		
	--initialize states with upper quota
	for _, v in pairs(a_list) do
		v.seats = math.ceil(v.quota)
	end
	
	-- allocate remaining seats
	local md = sd
	while full_seating(a_list) == false do
		md = md + 1
		--calculate modified quotas rounded UP.
		for _, v in pairs(a_list) do
			v.seats = math.ceil(v.pop/md)
		end
	end
	
	if full_seating(a_list) == false then print("Adams failed") end
	return a_list
end

-- A helper for the Webster approach
function webster_apportioner(denom, working_list)
	for _, v in pairs(working_list) do
		local mq = v.pop/denom
		decimal = mq - math.floor(mq)
		if decimal < 0.5 then
			v.seats = math.floor(mq)
		else
			v.seats = math.ceil(mq)
		end
	end
end

function webster(master_array)
	local w_list = master_array
	
	webster_apportioner(sd, w_list)
	
	local md = sd
	while full_seating(w_list) == false do
		md = md - 1
		--assign new quotas to states based on modified divisor
		webster_apportioner(md, w_list)
	end
	
	if full_seating(w_list) == false then print("Huntington-Hill failed") end
	return w_list
end

function huntington_hill(master_array)
	local hh_list = master_array
	
	local empty_seats = available_seats
	
	--initialize states with 1 seat
	for _, v in pairs (hh_list) do
		v.seats = 1
		empty_seats = empty_seats - 1
	end
	
	-- allocate remaining seats
	while empty_seats > 0 do
		local max = 0
		local maxIndex = 0
		for _, v in pairs (hh_list) do
			local numSeats = v.seats
			local alloc = v.pop/math.sqrt(numSeats*(numSeats + 1))
			if (alloc > max) then
				max = alloc
				maxIndex = _
			end
		end
		hh_list[maxIndex].seats = hh_list[maxIndex].seats + 1
		empty_seats = empty_seats - 1
	end
	
	if full_seating(hh_list) == false then print("Huntington-Hill failed") end
	return hh_list
end

-- Print percent errors for each approach.
print("Hamilton-Vinton error: " .. percent_error(hamilton_vinton(census_data)))
print("Jefferson error: " .. percent_error(jefferson(census_data)))
print("Adams error: " .. percent_error(adams(census_data)))
print("Webster error: " .. percent_error(webster(census_data)))
print("Huntington-Hill error: " .. percent_error(huntington_hill(census_data)))
