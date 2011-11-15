# encoding: UTF-8

module Spontaneous::Render
  module Helpers
    autoload :StylesheetHelper, 'spontaneous/render/helpers/stylesheet_helper'
    autoload :ScriptHelper, 'spontaneous/render/helpers/script_helper'
    include StylesheetHelper
    include ScriptHelper
  end
end

