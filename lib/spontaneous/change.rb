# encoding: UTF-8

module Spontaneous
  class ChangeSet
    attr_reader :changes

    def initialize(changes)
      @changes = changes
    end
    def pages
      @pages ||= build_page_list
    end
    def build_page_list
      changes.inject([]) { |a, c| a += c.modified_list; a }.uniq.sort.map do |id|
        Content[id]
      end
    end
    def to_hash
      h = {
        :changes => changes.map { |c| c.to_hash },
      }
      h[:pages] = pages.map  do |page|
        {
          :id => page.id,
          :title => page.title.to_s.escape_js,
          :path => page.path
        }
      end
      h
    end
  end

  class Change < Sequel::Model(:changes)
    class << self
      alias_method :sequel_plugin, :plugin
    end

    sequel_plugin :yajl_serialization, :modified_list

    @@instance = nil

    class << self
      def record(&block)
        entry_point = @@instance.nil?
        @@instance ||= self.new(:modified_list => [])
        yield if block_given?
      ensure
        if entry_point and !@@instance.modified_list.empty?
          @@instance.save
        end
        @@instance = nil if entry_point
      end

      def recording?
        !@@instance.nil?
      end

      def push(page)
        if @@instance
          @@instance.push(page)
        end
      end

      def outstanding
        dependencies = dependency_map
        dependencies.map { |d| ChangeSet.new(d) }
      end

      def dependency_map
        grouped_changes = self.all.map { |c| [c] }
        begin
          modified = false
          grouped_changes.each_with_index do |inner, i|
            inner_ids = inner.map { |c| c.modified_list }.flatten
            grouped_changes[(i+1)..-1].each_with_index do |outer, j|
              outer_ids = outer.map { |c| c.modified_list }.flatten
              if !(inner_ids & outer_ids).empty?
                modified = true
                grouped_changes.delete(outer)
                grouped_changes[i] += outer
              end
            end
          end
        end while modified

        grouped_changes
      end
    end

    def after_initialize
      super
      self.modified_list ||= []
    end

    def push(page)
      self.modified_list << page.id
    end

    def before_update
      self.modified_list.uniq!
    end

    def modified
      @modified ||= modified_list.map { |id| Content[id] }
    end

    alias_method :pages, :modified

    def &(change)
      self.modified_list & change.modified_list
    end
    
    def to_hash
      {
        :id => self.id,
        :created_at => self.created_at.to_s
      }
    end
  end
end