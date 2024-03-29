local config = {
	options = {},
	layout = {
		tmux = '-p90%,60%',
		window = { width = 0.9, height = 0.6 },
	},
}

local merge_options = function(options)
	return {
		options = vim.list_extend(options, config.options),
		layout = config.layout,
	}
end

local run = function(args, c)
	vim.fn['fzf#run']({
		source = args.source,
		sink = args.sink,
		options = c.options,
		tmux = c.layout.tmux,
		window = c.layout.window,
	})
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
