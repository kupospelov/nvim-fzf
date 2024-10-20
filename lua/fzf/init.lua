local config = {
	options = {},
	layout = {
		tmux = { '-p90%,60%' },
		window = { width = 0.9, height = 0.6 },
	},
}

local merge_options = function(options)
	return {
		options = vim.list_extend(options, config.options),
		layout = config.layout,
	}
end

local process_output = function(output, args)
	if type(args.sink) == 'string' then
		vim.cmd({ cmd = args.sink, args = { vim.trim(output) } })
	elseif type(args.sink) == 'function' then
		args.sink(output)
	end
end

local quote = function(options)
	local result = {}
	for i, v in ipairs(options) do
		result[i] = string.format("'%s'", string.gsub(v, "'", "'\\''"))
	end
	return result
end

local build_cmd = function(cmd, args)
	local fzf = table.concat(cmd, ' ')

	if type(args.source) == 'table' then
		return string.format('%s << FZF_EOF\n%s\nFZF_EOF', fzf, table.concat(args.source, '\n'))
	end

	-- fzf ignores $FZF_DEFAULT_COMMAND w/o a pty that vim.system() cannot provide now.
	return string.format('%s | %s', args.source or '${FZF_DEFAULT_COMMAND:-find -type f}', fzf)
end

local fzf_term = function(args, c)
	local columns = vim.api.nvim_get_option('columns')
	local lines = vim.api.nvim_get_option('lines')
	local width = math.floor(columns * c.layout.window.width)
	local height = math.floor(lines * c.layout.window.height)

	local buffer = vim.api.nvim_create_buf(false, true)
	local window = vim.api.nvim_open_win(buffer, 1, {
		relative = 'editor',
		style = 'minimal',
		border = 'rounded',
		row = math.ceil((lines - height) / 2),
		col = math.ceil((columns - width) / 2),
		width = width,
		height = height,
	})
	if window == 0 then vim.notify('Failed to open a window', vim.log.levels.ERROR) end

	local tempfile = vim.fn.tempname()
	local cmd = { 'fzf' }
	vim.list_extend(cmd, quote(c.options))
	vim.list_extend(cmd, { '>', tempfile })

	vim.fn.termopen(build_cmd(cmd, args), {
		on_exit = function()
			vim.api.nvim_win_close(window, {})

			local file = io.open(tempfile, 'r')
			if file == nil then return end

			local output = file:read('*all')
			os.remove(tempfile)
			if output == '' then return end

			process_output(output, args)
		end,
	})
	vim.cmd({ cmd = 'startinsert' })
end

local fzf_tmux = function(args, c)
	local cmd = { 'fzf-tmux' }
	vim.list_extend(cmd, quote(c.layout.tmux))
	vim.list_extend(cmd, quote(c.options))

	local result = vim.system({ 'sh', '-c', build_cmd(cmd, args) }, { text = true }):wait()
	if result.code == 130 then
		return
	elseif result.code ~= 0 and result.code ~= 129 then
		vim.notify('Cannot run the command: ' .. result.stderr, vim.log.levels.ERROR)
		return
	end

	process_output(result.stdout, args)
end

local run = function(args, c)
	if os.getenv('TMUX') and c.layout.tmux then
		fzf_tmux(args, c)
	else
		fzf_term(args, c)
	end
end

local M = {}

M.setup = function(c)
	assert(c, 'no config overrides provided')
	config = vim.tbl_extend('force', config, c)
end

M.buffers = function()
	local bufinfo = vim.fn.getbufinfo({ buflisted = true })
	table.sort(bufinfo, function(b1, b2) return b1.lastused > b2.lastused end)

	local buffers = {}
	for _, b in pairs(bufinfo) do
		local name = b.name == '' and '[No Name]' or vim.fn.bufname(b.bufnr)
		local flags = b.changed == 1 and '\t[+]' or ''
		buffers[#buffers + 1] = '[' .. b.bufnr .. ']\t' .. name .. flags
	end

	run({
		source = buffers,
		sink = function(line)
			local bufnr = string.match(line, '%d+')
			vim.api.nvim_win_set_buf(0, tonumber(bufnr))
		end,
	}, merge_options({ '--header-lines', '1' }))
end

M.files = function(source)
	assert(not source or type(source) == 'string', 'source must be a string')
	run({
		source = source,
		sink = 'e',
	}, config)
end

return M
