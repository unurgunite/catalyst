require "../../spec_helper"

module Catalyst
  describe MethodIndex do
    describe ".index_methods" do
      it "returns the body line range of a method, excluding def and end" do
        code = <<-CR
          def greet
            puts "hi"
            puts "bye"
          end
          CR
        index = MethodIndex.index_methods(code)
        index.size.should eq(1)
        index[1].body.should eq(2..3)
        index[1].name.should eq("greet")
      end

      it "records whether the method takes a block" do
        code = <<-CR
          def with_block(&)
            yield
          end

          def without_block
            1
          end
          CR
        index = MethodIndex.index_methods(code)
        index[1].takes_block.should be_true
        index[5].takes_block.should be_false
      end

      it "skips a one-line method" do
        # A body range of `def f; 1; end` would be empty; indexing it as
        # 2..1 is not useful, so such methods are left out entirely.
        MethodIndex.index_methods(%(def f\n  1\nend\n)).size.should eq(1)
        MethodIndex.index_methods(%(def f\n  1\nend\n))[1].body.should eq(2..2)
      end

      it "returns an empty index for source that does not parse" do
        MethodIndex.index_methods("def broken(").should be_empty
      end

      it "indexes each method in a type body separately" do
        code = <<-CR
          class Box
            def outer
              value = 1
              value
            end

            def inner
              2
            end
          end
          CR
        index = MethodIndex.index_methods(code)
        index.size.should eq(2)
        index[2].name.should eq("outer")
        index[7].name.should eq("inner")
      end
    end

    describe ".methods_taking_block" do
      it "reports true when any overload takes a block" do
        code = <<-CR
          def log(message : String)
            puts message
          end

          def log(message : String, &)
            puts yield
          end
          CR
        MethodIndex.methods_taking_block(code)["log"].should be_true
      end

      it "reports false when no overload takes a block" do
        code = <<-CR
          def log(message : String)
            puts message
          end
          CR
        MethodIndex.methods_taking_block(code)["log"].should be_false
      end
    end

    describe ".enclosing_method" do
      methods = MethodIndex.index_methods(<<-CR)
        class Box
          def outer
            value = 1
            value
          end

          def inner
            2
          end
        end
        CR

      it "finds the method body containing a line" do
        MethodIndex.enclosing_method(methods, 3).should eq(3..4)
      end

      it "finds the second method's body for a line inside it" do
        MethodIndex.enclosing_method(methods, 7).should eq(8..8)
      end

      it "returns nil at top level" do
        MethodIndex.enclosing_method(methods, 20).should be_nil
      end

      it "treats the def line as part of its own method" do
        # A finding on the `def` line (a default argument, say) belongs to
        # that method, so the range starts there rather than one line later.
        MethodIndex.enclosing_method(methods, 2).should eq(3..4)
      end
    end

    describe ".enclosing_def_line" do
      methods = MethodIndex.index_methods(<<-CR)
        def greet
          puts "hi"
        end
        CR

      it "returns the line the def starts on" do
        MethodIndex.enclosing_def_line(methods, 2).should eq(1)
      end

      it "returns nil outside any method" do
        MethodIndex.enclosing_def_line(methods, 9).should be_nil
      end
    end
  end
end
