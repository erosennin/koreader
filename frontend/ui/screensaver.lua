local DocumentRegistry = require("document/documentregistry")
local UIManager = require("ui/uimanager")
local Screen = require("ui/screen")
local DocSettings = require("docsettings")
local DEBUG = require("dbg")
local _ = require("gettext")

local Screensaver = {
}

function Screensaver:getCoverImage(file)
    local ImageWidget = require("ui/widget/imagewidget")
    local CenterContainer = require("ui/widget/container/centercontainer")
    local FrameContainer = require("ui/widget/container/framecontainer")
    local AlphaContainer = require("ui/widget/container/alphacontainer")
    local image_height
    local image_width
    local screen_height = Screen:getHeight()
    local screen_width = Screen:getWidth()
    local doc = DocumentRegistry:openDocument(file)
    if doc then
        local image = doc:getCoverPageImage()
        doc:close()
        local lastfile = G_reader_settings:readSetting("lastfile")
        local data = DocSettings:open(lastfile)
        local proportional_cover = data:readSetting("proportional_screensaver")
        if image then
            if proportional_cover then
                image_height = image:getHeight()
                image_width = image:getWidth()
                local image_ratio = image_width / image_height
                local screen_ratio = screen_width / screen_height
                if image_ratio < 1 then
                    image_height = screen_height
                    image_width = image_height * image_ratio
                else
                    image_width = screen_width
                    image_height = image_width / image_ratio
                end
            else
                image_height = screen_height
                image_width = screen_width
            end
            local image_widget = ImageWidget:new{
                image = image,
                width = image_width,
                height = image_height,
            }
            return AlphaContainer:new{
                alpha = 1,
                height = screen_height,
                width = screen_width,
                CenterContainer:new{
                    dimen = Screen:getSize(),
                    FrameContainer:new{
                        bordersize = 0,
                        padding = 0,
                        height = screen_height,
                        width = screen_width,
                        image_widget
                    }
                }
            }
        end
    end
end

function Screensaver:getRandomImage(dir)
    local ImageWidget = require("ui/widget/imagewidget")
    local pics = {}
    local i = 0
    math.randomseed(os.time())
    for entry in lfs.dir(dir) do
        if lfs.attributes(dir .. entry, "mode") == "file" then
            local extension = string.lower(string.match(entry, ".+%.([^.]+)") or "")
            if extension == "jpg" or extension == "jpeg" or extension == "png" then
                i = i + 1
                pics[i] = entry
            end
        end
    end
    local image = pics[math.random(i)]
    if image then
        image = dir .. image
        if lfs.attributes(image, "mode") == "file" then
            return ImageWidget:new{
                file = image,
                width = Screen:getWidth(),
                height = Screen:getHeight(),
            }
        end
    end
end

function Screensaver:show()
    DEBUG("show screensaver")
    local InfoMessage = require("ui/widget/infomessage")
    -- first check book cover image
    if KOBO_SCREEN_SAVER_LAST_BOOK then
        local lastfile = G_reader_settings:readSetting("lastfile")
        local data = DocSettings:open(lastfile)
        local exclude = data:readSetting("exclude_screensaver")
        if not exclude then
            self.suspend_msg = self:getCoverImage(lastfile)
        end

    end
    -- then screensaver directory or file image
    if not self.suspend_msg then
        if type(KOBO_SCREEN_SAVER) == "string" then
            local file = KOBO_SCREEN_SAVER
            if lfs.attributes(file, "mode") == "directory" then
                if string.sub(file,string.len(file)) ~= "/" then
                   file = file .. "/"
                end
                self.suspend_msg = self:getRandomImage(file)
            elseif lfs.attributes(file, "mode") == "file" then
                local ImageWidget = require("ui/widget/imagewidget")
                self.suspend_msg = ImageWidget:new{
                    file = file,
                    width = Screen:getWidth(),
                    height = Screen:getHeight(),
                }
            end
        end
    end
    -- fallback to suspended message
    if not self.suspend_msg then
        self.suspend_msg = InfoMessage:new{ text = _("Suspended") }
    end
    UIManager:show(self.suspend_msg)
end

function Screensaver:close()
    DEBUG("close screensaver")
    if self.suspend_msg then
        UIManager:close(self.suspend_msg)
        self.suspend_msg = nil
    end
end

return Screensaver
