# encoding: UTF-8

require 'test_helper'


class StylesTest < MiniTest::Spec

  def template_root
    @@style_root
  end

  context "template root" do
    should "be settable" do
      File.exists?(template_root).should be_true
      Spontaneous.template_root = template_root
      Spontaneous.template_root.should == template_root
    end
  end

  def self.startup
    @@style_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/styles"))
    Spontaneous.template_root = @@style_root
    Spontaneous::Render.use_development_renderer
  end

  context "piece styles" do
    setup do
      class ::TemplateClass < Content; end
      class ::TemplateSubClass1 < TemplateClass; end
      class ::TemplateSubClass2 < TemplateClass; end
      class ::InvisibleClass < Content; end
    end

    teardown do
      Object.send(:remove_const, :TemplateClass)
      Object.send(:remove_const, :TemplateSubClass1)
      Object.send(:remove_const, :TemplateSubClass2)
    end

    context "default style" do
      setup do
        @piece = TemplateClass.new
      end

      should "derive path from owning class and name" do
        @piece.style.template.should == 'template_class'
      end

      should "render using correct template" do
        @piece.render.should == "template_class.html.cut\n"
      end

      should "be able to give a list of available formats" do
        @piece.style.formats.should == [:epub, :html, :pdf]
      end

      should "simply render an empty string if no templates are available" do
        skip ">>>> Need to find a consistent way to do this without repetition in rendering contexts"
        piece = InvisibleClass.new
        piece.render.should == ""
      end
    end


    context "named styles" do
      should "use template found in class directory if exists" do
        TemplateClass.style :named1
        piece = TemplateClass.new
        piece.style.template.should == 'template_class/named1'
        piece.render.should == "template_class/named1.html.cut\n"
      end

      should "use template in template root with correct name if it exists" do
        TemplateClass.style :named2
        piece = TemplateClass.new
        piece.style.template.should == 'named2'
        piece.render.should == "named2.html.cut\n"
      end

      should "allow passing of directory/stylename" do
        TemplateClass.style :'orange/apple'
        piece = TemplateClass.new
        piece.style.template.should == 'orange/apple'
        piece.render.should == "orange/apple.html.cut\n"
      end

      should "default to styles marked as 'default'" do
        TemplateClass.style :named1
        TemplateClass.style :named2, :default => true
        piece = TemplateClass.new
        piece.style.template.should == 'named2'
        piece.render.should == "named2.html.cut\n"
      end
    end

    context "switching styles" do
      setup do
        TemplateClass.style :named1
        TemplateClass.style :named2, :default => true
        @piece = TemplateClass.new
        @piece.style.template.should == 'named2'
        @piece.render.should == "named2.html.cut\n"
      end

      should "be possible" do
        @piece.style = :named1
        @piece.style.template.should == 'template_class/named1'
        @piece.render.should == "template_class/named1.html.cut\n"
      end

      should "persist" do
        @piece.style = :named1
        @piece.save
        @piece = Content[@piece.id]
        @piece.style.template.should == 'template_class/named1'
      end
    end

    context "inheriting styles" do
      should "use default for sub class if it exists" do
        piece = TemplateSubClass1.new
        piece.style.template.should == 'template_sub_class1'
      end

      should "fall back to default style for superclass if default for class doesn't exist" do
        piece = TemplateSubClass2.new
        piece.style.template.should == 'template_class'
      end
      should "fall back to defined default style for superclass if default for class doesn't exist" do
        TemplateClass.style :named1
        piece = TemplateSubClass2.new
        piece.style.template.should == 'template_class/named1'
      end
    end




    # context "inline templates" do
    #   setup do
    #     @class = Class.new(Content)
    #   end
    #   should "be definiable" do
    #     @class.style :simple
    #     @class.styles.length.should == 1
    #     t = @class.styles.first
    #     t.name.should == :simple
    #   end

    #   should "have configurable filenames" do
    #     @class.style :simple, :filename => "funky"
    #     t = @class.styles.first
    #     t.filename.should == "funky.html.cut"
    #   end

    #   should "have sane default titles" do
    #     @class.style :simple_style
    #     t = @class.styles.first
    #     t.title.should == "Simple Style"
    #   end

    #   should "have configurable titles" do
    #     @class.style :simple, :title => "A Simple Style"
    #     t = @class.styles.first
    #     t.title.should == "A Simple Style"
    #   end

    #   should "be accessable by name" do
    #     @class.style :simple
    #     @class.style :complex
    #     @class.styles[:simple].should == @class.styles.first
    #   end

    #   should "have #styles as a shortcut for #inliine_styles" do
    #     @class.style :simple
    #     @class.styles.should == @class.styles
    #   end

    #   should "take the first style as the default" do
    #     @class.style :simple
    #     @class.style :complex
    #     @class.styles.default.should == @class.styles[:simple]
    #   end

    #   should "honour the :default flag" do
    #     @class.style :simple
    #     @class.style :complex, :default => true
    #     @class.styles.default.should == @class.styles[:complex]
    #   end
    # end

    # context "assigned styles" do
    #   setup do
    #     class ::StyleTestClass < Content
    #       style :first_style
    #       style :default_style, :default => true
    #     end

    #     @a = StyleTestClass.new
    #     @b = StyleTestClass.new
    #     @a << @b
    #   end

    #   teardown do
    #     Object.send(:remove_const, :StyleTestClass)
    #   end

    #   should "assign the default style" do
    #     @a.pieces.first.style.should == ::StyleTestClass.styles.default
    #   end

    #   should "persist" do
    #     @a.save
    #     @b.save
    #     @a = StyleTestClass[@a.id]
    #     @a.pieces.first.style.should == ::StyleTestClass.styles.default
    #   end

    #   should "be settable" do
    #     @a.pieces.first.style = StyleTestClass.styles[:first_style]
    #     @a.save
    #     @a = StyleTestClass[@a.id]
    #     @a.pieces.first.style.should == ::StyleTestClass.styles[:first_style]
    #   end

    #   context "direct piece access" do
    #     setup do
    #       @a.pieces.first.style = StyleTestClass.styles[:first_style]
    #       @a.save
    #       piece_id = @a.pieces.first.target.id
    #       @piece = StyleTestClass[piece_id]
    #     end

    #     should "be accessible directly for pieces" do
    #       @piece.style.should == ::StyleTestClass.styles[:first_style]
    #     end

    #     should "not be settable directly on bare pieces" do
    #       lambda { @piece.style = ::StyleTestClass.styles.default }.must_raise(NoMethodError)
    #     end
    #   end
    # end

    # context "inline templates" do
    #   setup do
    #     class ::InlineTemplateClass < Content
    #       field :title

    #       template 'title: {{title}}'
    #     end

    #     @a = InlineTemplateClass.new
    #     @a.title = "Total Title"
    #   end

    #   teardown do
    #     Object.send(:remove_const, :InlineTemplateClass)
    #   end

    #   should "be used to render the content" do
    #     @a.render.should ==  "title: Total Title"
    #   end
    # end

    # context "default styles" do
    #   class ::DefaultStyleClass < Spontaneous::Box
    #     field :title
    #   end

    #   class ::WithDefaultStyleClass < Content
    #     field :title
    #   end
    #   class ::WithoutDefaultStyleClass < Content
    #     field :title
    #     box :with_style, :type => :DefaultStyleClass
    #   end
    #   setup do
    #     Content.delete

    #     @with_default_style = WithDefaultStyleClass.new
    #     @with_default_style.title = "Total Title"
    #     @without_default_style = WithoutDefaultStyleClass.new
    #     @without_default_style.title = "No Title"
    #     @without_default_style.with_style.title = "Box Title"
    #     # @without_default_style.with_style.path = "Box Title"
    #   end

    #   teardown do
    #     Content.delete
    #     # Object.send(:remove_const, :DefaultStyleClass)
    #     # Object.send(:remove_const, :WithDefaultStyleClass)
    #     # Object.send(:remove_const, :WithoutDefaultStyleClass)
    #   end

    #   should "be used when available" do
    #     @with_default_style.render.should == "Title: Total Title\\n"
    #   end

    #   should "be used by boxes too" do
    #     @without_default_style.with_style.render.should == "Title: Box Title\\n"
    #   end

    #   should "fallback to anonymous style when default style template doesn't exist" do
    #     @without_default_style.render.should == "Title: Box Title\\n"
    #   end
    # end
  end
end
