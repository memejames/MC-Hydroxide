local UserInput = game:GetService("UserInputService")

local Dropdown = {}
local dropdownCache = {}

function Dropdown.new(instance)
    local dropdown = {}
    local selection = instance.Selection
    local collapseButton = instance.Collapse

    collapseButton.TouchTap:Connect(function()
        local collapsed = not dropdown.Collapsed
        selection.Visible = not collapsed
        dropdown.Collapsed = collapsed
    end)

    for _, v in pairs(instance.Selection.Clip.List:GetChildren()) do
        if v:IsA("TextButton") then
            v.TouchTap:Connect(function()
                dropdown:Collapse(v.Name)
            end)
        end
    end

    dropdown.Collapse = Dropdown.collapse
    dropdown.Collapsed = true
    dropdown.Instance = instance
    dropdown.SetSelected = Dropdown.setSelected
    dropdown.SetCallback = Dropdown.setCallback

    table.insert(dropdownCache, dropdown)

    return dropdown
end

function Dropdown.setSelected(dropdown, buttonName)
    local instance = dropdown.Instance
    local selection = instance.Selection.Clip.List
    local button = selection:FindFirstChild(buttonName)

    if button then
        instance.Label.Text = buttonName

        dropdown.Collapsed = true
        dropdown.Selected = button
        dropdown:Callback(button)
    end
end

function Dropdown.collapse(dropdown, name)
    local instance = dropdown.Instance
    local selection = instance.Selection

    if name then
        local button = selection.Clip.List:FindFirstChild(name)

        if button then
            instance.Label.Text = button.Name

            dropdown.Selected = button
            dropdown:Callback(button)
        end
    end

    selection.Visible = false
    dropdown.Collapsed = true
end

function Dropdown.setCallback(dropdown, callback)
    if not dropdown.Callback then
        dropdown.Callback = callback
    end
end

-- touch events for collapsing the dropdown on mobile devices
local function collapseAllDropdowns()
    for _, dropdown in pairs(dropdownCache) do
        dropdown:Collapse()
    end
end

local touchInput = UserInput.TouchEnded:Connect(function(input)
    collapseAllDropdowns()
end)

return Dropdown
