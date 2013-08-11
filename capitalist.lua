-- corn by yarlesp
-- pl development 2013

capitalist = {	name = "Mr. soandso", 
				fortune = 10, 			-- amt of corn
				infamous = false,		-- placeholder, eventually killing people or being especially brutal will earn you a repuation
				industrial = false, 	-- whether you're allowed to invest in factories
				agricultural = true, 	-- whether you're allowed to invest in farming
				commercial = false, 	-- whether you're allowed to invest in banking
				employed_ag = {}, 		-- contains your agricultural workers
				employed_ind = {},		-- contains your industrial workers
				employed = 0,			-- size of above two tables
				towns = {},				-- all the towns you're allowed to marshal labor from
				fields = {} }			-- all the fields you're investing in

function capitalist.update()
	if capitalist.agricultural then
		-- capital and labor must be allocated every spring
		-- nothing stays over from year to year
		if game.season == 4 then -- winter (i.e. right before the new year)
			for i = 1, #capitalist.fields do
				capitalist.fields[i]:update()
			end
			capitalist.fields, capitalist.employed_ind, capitalist.employed_ag = {}, {}, {}
			employed = #capitalist.employed_ag + #capitalist.employed_ind
		elseif game.season == 3 then -- fall
			for i = 1, #capitalist.fields do
				capitalist.fortune = capitalist.fortune - game.rent_rate -- rent
				capitalist.fields[i].manor.store = capitalist.fields[i].manor.store + game.rent_rate -- rent is uniform TODO
				if capitalist.fields[i].activity.planting then 
					capitalist.fortune = capitalist.fields[i].fertility + capitalist.fortune -- raw profits
				elseif capitalist.fields[i].activity.improving then  -- handling investment
					capitalist.fields[i].fertility = capitalist.fields[i].fertility + 1
					capitalist.fields[i].intensity.k = capitalist.fields[i].intensity.k + 1/(2 + game.capital_tech)
				end
			end
			-- paying workers
			for i = 1, #capitalist.employed_ag do
				capitalist.employed_ag[i].savings = capitalist.employed_ag[i].savings + (game.wage_rate * capitalist.employed_ag[i].utilization)
				capitalist.fortune = capitalist.fortune - (game.wage_rate * capitalist.employed_ag[i].utilization)
			end
			if game.options.decay then capitalist.fortune = math.floor(capitalist.fortune) end -- just to keep the numbers round. imagine it's ineffeciency or something
		end
	end

	if capitalist.industrial then
		-- TODO: industry, to present a place for capital to exit to if, say, agriculture isnt profitable anymore
	end
end

-- takes a key
-- modifies a ton of shit based on that key
-- side effects: operates on all tiles currently selected, changing their status, changing the amount of labor employed
function capitalist.keypressed( key )
	local min = { math.min(land.start_focus[1], land.end_focus[1]) , math.min(land.start_focus[2], land.end_focus[2]) }
	local max = { math.max(land.start_focus[1], land.end_focus[1]) , math.max(land.start_focus[2], land.end_focus[2]) }
	for y = min[2], max[2] do
		for x = min[1], max[1] do
			local l
			print(x.." "..y.." out of "..width.." "..height)
			if land.map[y][x] then l = land.map[y][x] end
			if l and game.season == 1 and l.fertility then -- short cut evaluation 
			  	-- pure readability, I guess locals are faster as well. 
			  	local can_plant = capitalist.fortune > l.intensity.k and l.fertility > 0
			  	local can_invest = capitalist.fortune > (l.intensity.k * l.to_improve) and l.fertility > 0
			  	local can_work = l:check_labor(l.intensity.l)

			  	local k_required = l.intensity.k
			  	local l_required = l.intensity.l
			  	local i_required = l.to_improve

			  	local planted = l.activity.planting
			  	local invested = l.activity.improving

			  	local fallow = not planted and not invested

				local function add_field()
					l.worker = can_work:get_labor(l.intensity.l)
					capitalist.fields[#capitalist.fields + 1] = l 
					local already_working = false
					for i = 1, #capitalist.employed_ag do
						if capitalist.employed_ag[i] == l.worker then
							l.worker.utilization = l.worker.utilization + l.intensity.l
							if l.worker.utilization >= game.labor_per then l.worker.available = false end 
							already_working = true
						end
					end
					if not already_working then 
						capitalist.employed_ag[#capitalist.employed_ag + 1] = l.worker
						l.worker.utilization = l.worker.utilization + l.intensity.l
						if l.worker.utilization >= game.labor_per then l.worker.available = false end 
					end
				end

				local function remove_field()
					local i = 1
					while capitalist.fields[i] do
						if l == capitalist.fields[i] then
							local j = 1
							while capitalist.employed_ag[j] do
								if l.worker == capitalist.employed_ag[j] then
									l.worker.utilization = l.worker.utilization - l.intensity.l
									l.worker.available = true
									if l.worker.utilization - .01 <= 0 then -- 1/3 + 1/3 + 1/3 - 1/3 - 1/3 - 1/3 doesn't actually equal zero in lua. 
										l.worker.utilization = 0
										table.remove(capitalist.employed_ag, j)
									end
								end
								j = j + 1
							end
							table.remove(capitalist.fields, i)
						end
						i = i + 1
					end
				end

				if key == "p" then --plant
					if fallow and can_plant and can_work then
						add_field()
						capitalist.fortune = capitalist.fortune - k_required 
						l.activity.planting = true
						l.activity.improving = false
					elseif invested then -- if its already invested that implies that the labor and capital already exist 
						capitalist.fortune = capitalist.fortune + (k_required * (i_required / k_required) )
						l.activity.planting = true
						l.activity.improving = false
					end
				elseif key == "i" then -- invest
					if fallow and can_invest and can_work then
						add_field()
						capitalist.fortune = capitalist.fortune - (k_required * i_required)
						l.activity.improving = true
						l.activity.planting = false
					elseif planted and not invested then 
						if capitalist.fortune > (k_required * i_required) then -- if there's corn left in there
							capitalist.fortune = capitalist.fortune - (k_required * i_required)
							capitalist.fortune = capitalist.fortune + k_required
							l.activity.planting = false
							l.activity.improving = true
						end
					end
				elseif key == "u" and not fallow then -- uproot, get the corn back. 
					remove_field()
					if planted then capitalist.fortune = capitalist.fortune + k_required end
					if invested then capitalist.fortune = capitalist.fortune + (k_required * i_required) end
					l.activity.planting = false
					l.activity.improving = false
				elseif key == "c" then
					-- TODO: clearing forests
				end
				capitalist.employed = #capitalist.employed_ag + #capitalist.employed_ind
			end
		end
	end
end