function table.Filter(tab, callback)
	local i, e, c = 0, #tab, 1

	if (e == 0) then
		goto abort
	end

	::startfilter::
	i = i + 1
	if callback(tab[i]) then
		tab[c] = tab[i]
		c = c + 1
	end

	if (i < e) then
		goto startfilter
	end

	i = c - 1
	::startprune::
	i = i + 1
	tab[i] = nil

	if (i < e) then
		goto startprune
	end

	::abort::

	return tab
end

function table.FilterCopy(tab, callback)
	local ret = {}

	local i, e, c = 0, #tab, 1

	if (e == 0) then
		goto abort
	end

	::startfilter::
	i = i + 1
	if callback(tab[i]) then
		ret[c] = tab[i]
		c = c + 1
	end

	if (i < e) then
		goto startfilter
	end

	::abort::

	return ret
end

function table.ConcatKeys(tab, concatenator)
	concatenator = concatenator or ""
	local s = ""

	for key in pairs(tab) do
		s = s .. key .. concatenator
	end

	return s:sub(1, -#concatenator - 1)
end
