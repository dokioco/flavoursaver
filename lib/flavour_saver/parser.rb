require 'rltk'
require 'rltk/ast'
require 'flavour_saver/nodes'

module FlavourSaver
  class Parser < RLTK::Parser

    class UnbalancedBlockError < StandardError; end

    class Environment < RLTK::Parser::Environment
      def push_block block
        blocks.push(block.name)
        block
      end

      def pop_block block
        b = blocks.pop
        raise UnbalancedBlockError, "Unable to find matching opening for {{/#{block.name}}}" if b != block.name
        block
      end

      def blocks
        @blocks ||= []
      end
    end

    left :DOT
    right :EQ

    production(:template) do
      clause('template_item+') { |items| TemplateNode.new(items) }
      clause('') { TemplateNode.new([]) }
    end

    production(:template_item) do
      clause('OUT') { |output_string| OutputNode.new(output_string) }
      clause('expression') { |e| e }
      clause('COMMENT') { |comment_string| CommentNode.new(comment_string) }
    end

    production(:expression) do
      clause('block_expression') { |e| e }
      clause('expr')          { |e| ExpressionNode.new(e) }
      clause('expr_safe')     { |e| SafeExpressionNode.new(e) }
      clause('partial')       { |e| e }
    end

    production(:partial) do
      clause('EXPRSTGT WHITE? STRING WHITE? EXPRE') { |_,_,e,_,_| PartialNode.new(e,[]) }
      clause('EXPRSTGT WHITE? ident_or_literal WHITE? EXPRE') { |_,_,e,_,_| PartialNode.new(e,[]) }
      clause('EXPRSTGT WHITE? ident_or_literal WHITE? call WHITE? EXPRE') { |_,_,e0,_,e1,_,_| PartialNode.new(e0,e1,nil) }
      clause('EXPRSTGT WHITE? ident_or_literal WHITE? lit WHITE? EXPRE') { |_,_,e0,_,e1,_,_| PartialNode.new(e0,[],e1) }
    end

    production(:block_expression) do
      clause('expr_bl_start template expr_else template expr_bl_end') { |e0,e1,_,e3,e2| BlockExpressionNodeWithElse.new([e0], e1,e2,e3) }
      clause('expr_bl_start template expr_bl_end') { |e0,e1,e2| BlockExpressionNode.new([e0],e1,e2) }
      clause('expr_bl_inv_start template expr_else template expr_bl_end') { |e0,e1,_,e3,e2| BlockExpressionNodeWithElse.new([e0], e2,e2,e1) }
      clause('expr_bl_inv_start template expr_bl_end') { |e0,e1,e2| BlockExpressionNodeWithElse.new([e0],TemplateNode.new([]),e2,e1) }
    end

    production(:expr_else) do
      clause('EXPRST WHITE? ELSE WHITE? EXPRE') { |_,_,_,_,_| }
      clause('EXPRSTHAT WHITE? EXPRE') { |_,_,_| }
    end

    production(:expr) do
      clause('EXPRST expression_contents EXPRE') { |_,e,_| e }
    end

    production(:expr_safe) do
      clause('TEXPRST expression_contents TEXPRE') { |_,e,_| e }
      clause('EXPRSTAMP expression_contents EXPRE') { |_,e,_| e }
    end

    production(:expr_bl_start) do
      clause('EXPRSTHASH WHITE? IDENT WHITE? EXPRE') { |_,_,e,_,_| push_block CallNode.new(e,[]) }
      clause('EXPRSTHASH WHITE? IDENT WHITE arguments WHITE? EXPRE') { |_,_,e,_,a,_,_| push_block CallNode.new(e,a) }
    end

    production(:expr_bl_inv_start) do
      clause('EXPRSTHAT WHITE? IDENT WHITE? EXPRE') { |_,_,e,_,_| push_block CallNode.new(e,[]) }
      clause('EXPRSTHAT WHITE? IDENT WHITE arguments WHITE? EXPRE') { |_,_,e,_,a,_,_| push_block CallNode.new(e,a) }
    end

    production(:expr_bl_end) do
      clause('EXPRSTFWSL WHITE? IDENT WHITE? EXPRE') { |_,_,e,_,_| pop_block CallNode.new(e,[]) }
    end

    production(:expression_contents) do
      clause('WHITE? call WHITE?') { |_,e,_| e }
      clause('WHITE? local WHITE?') { |_,e,_| [e] }
    end

    production(:call) do
      clause('object_path') { |e| e }
      clause('object_path WHITE arguments') { |e0,_,e1| e0.last.arguments = e1; e0 }
      clause('DOT') { |_| [CallNode.new('this', [])] }
    end

    production(:local) do
      clause('AT IDENT') { |_,e| LocalVarNode.new(e) }
    end

    production('arguments') do
      clause('argument_list') { |e| e }
      clause('argument_list WHITE hash') { |e0,_,e1| e0 + [e1] }
      clause('hash') { |e| [e] }
    end

    nonempty_list(:argument_list, [:object_path, :lit], :WHITE)

    production(:lit) do
      clause('string') { |e| e }
      clause('number') { |e| e }
      clause('BOOL') { |b| b ? TrueNode.new(true) : FalseNode.new(false) }
    end

    production(:string) do
      clause('STRING') { |e| StringNode.new(e) }
      clause('S_STRING') { |e| StringNode.new(e) }
    end

    production(:number) do
      clause('NUMBER') { |n| NumberNode.new(n) }
    end

    production(:hash) do
      clause('hash_item') { |e| e }
      clause('hash WHITE hash_item') { |e0,_,e1| e0.merge(e1) }
    end

    production(:hash_item) do
      clause('IDENT EQ string') { |e0,_,e1| { e0.to_sym => e1 } }
      clause('IDENT EQ number') { |e0,_,e1| { e0.to_sym => e1 } }
      clause('IDENT EQ object_path') { |e0,_,e1| { e0.to_sym => e1 } }
    end

    production(:object_sep) do
      clause('DOT') { |_| }
      clause('FWSL') { |_| }
    end

    nonempty_list(:object_path, :object, :object_sep)

    production(:object) do
      clause('IDENT') { |e| CallNode.new(e, []) }
      clause('LITERAL') { |e| LiteralCallNode.new(e, []) } # this is why we can't use ident_or_literal here
      clause('DOTDOTSLASH+ ident_or_literal') { |backtracks, name| ParentCallNode.new(name, [], backtracks.length) }
    end

    production(:ident_or_literal) do
      clause('IDENT') { |e| e }
      clause('LITERAL') { |e| e }
    end

    finalize

  end
end
