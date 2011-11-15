# encoding: UTF-8


module Spontaneous
  module Render
    class Renderer

      attr_reader :template_root

      def initialize(template_root)
        @template_root = template_root
      end

      def render_content(content, format=:html, params = {})
        # overwrite in subclasses
      end

      def render_string(template_string, content, format=:html, params = {})
        # overwrite in subclasses
      end

      def template_file(filename, format)
        Render.template_file(template_root, filename, format)
      end

      def extension
        Spontaneous.template_engine.extension
      end

      # protected

      def preview_renderer
        Spontaneous.template_engine.preview_renderer.new(template_root, cache?)
      end

      def publishing_renderer
        Spontaneous.template_engine.publishing_renderer.new(template_root, cache?)
      end

      def request_renderer
        Spontaneous.template_engine.request_renderer.new(template_root, cache?)
      end

      def cache?
        Spontaneous::Render.cache_templates?
      end
    end # Renderer
  end  # Render
end  # Spontaneous

