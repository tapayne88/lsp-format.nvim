local mock = require "luassert.mock"
local match = require "luassert.match"
local spy = require "luassert.spy"
local f = require "lsp-format"

local mock_client = {
    id = 1,
    name = "lsp-client-test",
    request = function(_, _, _, _) end,
    request_sync = function(_, _, _, _) end,
    supports_method = function(_) end,
    setup = function() end,
}

vim.lsp.buf_get_clients = function()
    local clients = {}
    clients[mock_client.name] = mock_client
    return clients
end
vim.lsp.get_client_by_id = function()
    return mock_client
end

describe("lsp-format", function()
    local c
    local api

    before_each(function()
        c = mock(mock_client, true)
        api = mock(vim.api)
        c.supports_method = function(_)
            return true
        end
        f.setup {}
        f.format_options = {}
        f.on_attach(c)
    end)

    after_each(function()
        mock.revert(c)
        mock.revert(api)
    end)

    it("[format] sends a valid format request", function()
        f.format {}
        assert.stub(c.request).was_called(1)
        assert.stub(c.request).was_called_with("textDocument/formatting", {
            options = {
                insertSpaces = false,
                tabSize = 8,
            },
            textDocument = {
                uri = "file://",
            },
        }, match.is_ref(f._handler), 1)
    end)

    it("[format_in_range] sends a valid format request", function()
        vim.lsp.util.make_given_range_params = function(_, _, _, _)
            return {
                range = {
                    ["end"] = {
                        character = 81,
                        line = 60,
                    },
                    start = {
                        character = 0,
                        line = 58,
                    },
                },
                textDocument = {
                    uri = "file://",
                },
            }
        end
        f.format_in_range {}
        assert.stub(c.request).was_called(1)
        assert.stub(c.request).was_called_with("textDocument/rangeFormatting", {
            options = {
                insertSpaces = false,
                tabSize = 8,
            },
            range = {
                ["end"] = {
                    character = 81,
                    line = 60,
                },
                start = {
                    character = 0,
                    line = 58,
                },
            },
            textDocument = {
                uri = "file://",
            },
        }, match.is_ref(f._handler), 1)
    end)

    describe("[format]", function()
        it("sends default format options", function()
            f.setup {
                lua = {
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
            }
            vim.bo.filetype = "lua"
            f.format {}
            assert.stub(c.request).was_called(1)
            assert.stub(c.request).was_called_with("textDocument/formatting", {
                options = {
                    insertSpaces = false,
                    tabSize = 8,
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
                textDocument = {
                    uri = "file://",
                },
            }, match.is_ref(f._handler), 1)
        end)

        it("sends format options", function()
            f.format {
                fargs = { "bool_test", "int_test=1", "string_test=string" },
            }
            assert.stub(c.request).was_called(1)
            assert.stub(c.request).was_called_with("textDocument/formatting", {
                options = {
                    insertSpaces = false,
                    tabSize = 8,
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
                textDocument = {
                    uri = "file://",
                },
            }, match.is_ref(f._handler), 1)
        end)

        it("overwrites default format options", function()
            f.setup {
                lua = {
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
            }
            vim.bo.filetype = "lua"
            f.format {
                fargs = { "bool_test=false", "int_test=2", "string_test=another_string" },
            }
            assert.stub(c.request).was_called(1)
            assert.stub(c.request).was_called_with("textDocument/formatting", {
                options = {
                    insertSpaces = false,
                    tabSize = 8,
                    bool_test = false,
                    int_test = 2,
                    string_test = "another_string",
                },
                textDocument = {
                    uri = "file://",
                },
            }, match.is_ref(f._handler), 1)
        end)
    end)

    describe("[format_in_range]", function()
        before_each(function()
            vim.lsp.util.make_given_range_params = function(_, _, _, _)
                return {
                    range = {
                        ["end"] = {
                            character = 81,
                            line = 60,
                        },
                        start = {
                            character = 0,
                            line = 58,
                        },
                    },
                    textDocument = {
                        uri = "file://",
                    },
                }
            end
        end)

        it("sends default format options", function()
            f.setup {
                lua = {
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
            }
            vim.bo.filetype = "lua"
            f.format_in_range {}
            assert.stub(c.request).was_called(1)
            assert.stub(c.request).was_called_with("textDocument/rangeFormatting", {
                options = {
                    insertSpaces = false,
                    tabSize = 8,
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
                range = {
                    ["end"] = {
                        character = 81,
                        line = 60,
                    },
                    start = {
                        character = 0,
                        line = 58,
                    },
                },
                textDocument = {
                    uri = "file://",
                },
            }, match.is_ref(f._handler), 1)
        end)

        it("sends format options", function()
            f.format_in_range {
                fargs = { "bool_test", "int_test=1", "string_test=string" },
            }
            assert.stub(c.request).was_called(1)
            assert.stub(c.request).was_called_with("textDocument/rangeFormatting", {
                options = {
                    insertSpaces = false,
                    tabSize = 8,
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
                range = {
                    ["end"] = {
                        character = 81,
                        line = 60,
                    },
                    start = {
                        character = 0,
                        line = 58,
                    },
                },
                textDocument = {
                    uri = "file://",
                },
            }, match.is_ref(f._handler), 1)
        end)

        it("overwrites default format options", function()
            f.setup {
                lua = {
                    bool_test = true,
                    int_test = 1,
                    string_test = "string",
                },
            }
            vim.bo.filetype = "lua"
            f.format_in_range {
                fargs = { "bool_test=false", "int_test=2", "string_test=another_string" },
            }
            assert.stub(c.request).was_called(1)
            assert.stub(c.request).was_called_with("textDocument/rangeFormatting", {
                options = {
                    insertSpaces = false,
                    tabSize = 8,
                    bool_test = false,
                    int_test = 2,
                    string_test = "another_string",
                },
                range = {
                    ["end"] = {
                        character = 81,
                        line = 60,
                    },
                    start = {
                        character = 0,
                        line = 58,
                    },
                },
                textDocument = {
                    uri = "file://",
                },
            }, match.is_ref(f._handler), 1)
        end)
    end)

    for _, format_command in ipairs { "format", "format_in_range" } do
        describe(string.format("[%s]", format_command), function()
            it("FormatToggle prevent/allow formatting", function()
                f.toggle { args = "" }
                f[format_command] {}
                assert.stub(c.request).was_called(0)

                f.toggle { args = "" }
                f[format_command] {}
                assert.stub(c.request).was_called(1)
            end)

            it("FormatDisable/Enable prevent/allow formatting", function()
                f.disable { args = "" }
                f[format_command] {}
                assert.stub(c.request).was_called(0)

                f.enable { args = "" }
                f[format_command] {}
                assert.stub(c.request).was_called(1)
            end)

            it("does not overwrite changes", function()
                local apply_text_edits = spy.on(vim.lsp.util, "apply_text_edits")
                c.request = function(_, params, handler, bufnr)
                    api.nvim_buf_get_var = function(_, var)
                        if var == "format_changedtick" then
                            return 9999
                        end
                        return 1
                    end
                    handler(nil, {}, { bufnr = bufnr, params = params })
                end
                f[format_command] {}
                assert.spy(apply_text_edits).was.called(0)
            end)

            it("does overwrite changes with force", function()
                local apply_text_edits = spy.on(vim.lsp.util, "apply_text_edits")
                c.request = function(_, params, handler, bufnr)
                    api.nvim_buf_get_var = function(_, var)
                        if var == "format_changedtick" then
                            return 9999
                        end
                        return 1
                    end
                    handler(nil, {}, { bufnr = bufnr, params = params })
                end
                f[format_command] { fargs = { "force=true" } }
                assert.spy(apply_text_edits).was.called(1)
            end)

            it("does not overwrite when in insert mode", function()
                local apply_text_edits = spy.on(vim.lsp.util, "apply_text_edits")
                c.request = function(_, params, handler, bufnr)
                    api.nvim_get_mode = function()
                        return "insert"
                    end
                    handler(nil, {}, { bufnr = bufnr, params = params })
                end
                f[format_command] {}
                assert.spy(apply_text_edits).was.called(0)
            end)

            it("does overwrite when in insert mode with force", function()
                local apply_text_edits = spy.on(vim.lsp.util, "apply_text_edits")
                c.request = function(_, params, handler, bufnr)
                    api.nvim_get_mode = function()
                        return "insert"
                    end
                    handler(nil, {}, { bufnr = bufnr, params = params })
                end
                f[format_command] { fargs = { "force=true" } }
                assert.spy(apply_text_edits).was.called(1)
            end)

            describe("excluding clients", function()
                describe("for filetypes", function()
                    it("does format when client is _NOT_ specified", function()
                        f.setup {
                            lua = {
                                exclude = { "NOT-lsp-client-test" },
                            },
                        }
                        vim.bo.filetype = "lua"
                        f[format_command] {}
                        assert.stub(c.request).was_called(1)
                    end)

                    it("doesn't format when client is specified", function()
                        f.setup {
                            lua = {
                                exclude = { "lsp-client-test" },
                            },
                        }
                        vim.bo.filetype = "lua"
                        f[format_command] {}
                        assert.stub(c.request).was_called(0)
                    end)
                end)

                describe("globally", function()
                    it("does format when client is _NOT_ specified", function()
                        f.setup {
                            exclude = { "NOT-lsp-client-test" },
                        }
                        vim.bo.filetype = "lua"
                        f[format_command] {}
                        assert.stub(c.request).was_called(1)
                    end)

                    it("doesn't format when client is specified", function()
                        f.setup {
                            exclude = { "lsp-client-test" },
                        }
                        vim.bo.filetype = "lua"
                        f[format_command] {}
                        assert.stub(c.request).was_called(0)
                    end)
                end)
            end)
        end)
    end
end)
