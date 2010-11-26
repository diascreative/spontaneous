# encoding: UTF-8

# is this unforgivable?
# i think it's kinda neat, if a tad fragile (to columns named 'content'...)
module Sequel
  class Dataset
    alias_method :_quote_identifier, :quote_identifier

    def quote_identifier(name)
      if name == "content"
        name = Spontaneous::Content.current_revision_table
      end
      _quote_identifier(name)
    end
  end
end

module Spontaneous::Plugins
  module Publishing

    module ClassMethods
      @@dataset = nil
      @@revision = nil
      @@publishable_classes = [Spontaneous::Content]

      def inherited(subclass)
        super
        add_publishable_class(subclass)
        # if @@dataset
          # activate_dataset(@@dataset)
        # end
      end


      def add_publishable_class(klass)
        @@publishable_classes << klass unless @@publishable_classes.include?(klass)
      end

      def current_revision_table
        revision_table(@@revision)
      end

      def revision_table(revision=nil)
        return 'content' if revision.nil?
        "__r#{revision.to_s.rjust(5, '0')}_content"
      end

      def revision
        @@revision
      end

      def reset_revision
        @@revision, @@dataset = revision_stack.first
        @@revision = nil
        activate_dataset(@@dataset)
        revision_stack.clear
      end

      def with_revision(revision=nil, &block)
        revision_push(revision)
        begin
          yield 
        ensure
          revision_pop
        end if block_given?
      end

      def with_editable(&block)
        with_revision(nil, &block)
      end

      def with_published(&block)
        with_revision(Spontaneous::Site.published_revision, &block)
      end

      def revision_push(revision)
        revision_stack.push([@@revision, (@@dataset || self.dataset)])
        @@dataset = revision_dataset(revision)
        @@revision = revision
        # activate_dataset(@@dataset)
      end

      def activate_dataset(dataset)
        # @@publishable_classes.each do |content_class|
        #   content_class.dataset = dataset unless content_class.dataset == dataset
        # end
      end

      def revision_pop
        @@revision, @@dataset = revision_stack.pop
        # activate_dataset(@@dataset)
      end

      def revision_stack
        @revision_stack ||= []
      end

      def revision_dataset(revision=nil)
        Spontaneous.database.dataset.from(revision_table(revision))
      end
    end

    module InstanceMethods
    end
  end
end
