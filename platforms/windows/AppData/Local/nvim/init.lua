if vim.g.vscode then
	local vscode = require("vscode-neovim")

	local function action(name)
		return function()
			vscode.action(name)
		end
	end

	vim.g.mapleader = " "

	vim.keymap.set("i", "<C-c>", "<Esc>")

	vim.keymap.set("i", "<C-j>", "{}<Esc>i")
	vim.keymap.set("i", "<C-k>", "[]<Esc>i")
	vim.keymap.set("i", "<C-l>", "<Esc>la")
	vim.keymap.set("i", "<C-h>", "<Esc>i")

	vim.keymap.set("n", "<leader>bd", action("workbench.action.closeActiveEditor"))
	vim.keymap.set("n", "<C-q>", action("workbench.action.closeActiveEditor"))

	--------------
	--- Editor ---
	--------------

	vim.keymap.set("n", "<leader>e", action("workbench.action.toggleSidebarVisibility"))

	------------------
	--- Navigation ---
	------------------

	vim.keymap.set("n", "<S-h>", action("workbench.action.previousEditorInGroup"))
	vim.keymap.set("n", "<S-l>", action("workbench.action.nextEditorInGroup"))

	vim.keymap.set("n", "<A-k>", action("workbench.action.increaseViewHeight"))
	vim.keymap.set("n", "<A-l>", action("workbench.action.increaseViewWidth"))
	vim.keymap.set("n", "<A-j>", action("workbench.action.decreaseViewHeight"))
	vim.keymap.set("n", "<A-h>", action("workbench.action.decreaseViewWidth"))

	vim.keymap.set("n", "<C-h>", action("workbench.action.navigateLeft"))
	vim.keymap.set("n", "<C-j>", action("workbench.action.navigateDown"))
	vim.keymap.set("n", "<C-k>", action("workbench.action.navigateUp"))
	vim.keymap.set("n", "<C-l>", action("workbench.action.navigateRight"))

	-----------
	--- LSP ---
	-----------

	vim.keymap.set("n", "gd", action("editor.action.revealDefinition"))
	vim.keymap.set("n", "gD", action("editor.action.revealDeclaration"))
	vim.keymap.set("n", "gi", action("editor.action.goToImplementation"))
	vim.keymap.set("n", "gr", action("editor.action.goToReferences"))
	vim.keymap.set("n", "<leader>D", action("editor.action.goToTypeDefinition"))
	vim.keymap.set("n", "<leader>cr", action("editor.action.rename"))
	vim.keymap.set("n", "<leader>ca", action("editor.action.autoFix"))

	vim.keymap.set("n", "<leader>rr", action("editor.action.refactor"))

	------------------
	--- Formatting ---
	------------------
	vim.keymap.set("n", "F", action("editor.action.formatDocument"))

	-------------------
	--- Search/Find ---
	-------------------

	vim.keymap.set("n", "<leader>/", action("workbench.action.findInFiles"))
	vim.keymap.set("n", "<leader>?", action("workbench.action.findInFiles"))
	vim.keymap.set("n", "<leader>sc", action("workbench.action.showCommands"))
	vim.keymap.set("n", "<leader>sf", action("workbench.action.quickOpen"))
	vim.keymap.set("n", "<leader><leader>", action("workbench.action.quickOpen"))
else
	-- ordinary Neovim
end
