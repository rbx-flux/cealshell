return {
    name = "clear",
    args = nil,
    callback = function()
        print(string.rep("\n", 50))
    end,
    description = "Clears the console.",
    manual = nil,
    signer = "cealshell",
    alias = {"cls"},
}