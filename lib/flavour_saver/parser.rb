require 'rltk'
require 'rltk/ast'
require 'flavour_saver/nodes'

module FlavourSaver
  class Parser < RLTK::Parser

    class UnbalancedBlockError < StandardError; end

    class Environment < RLTK::Parser::Environment
      def make_block_node(test, contents, alternate, closer_name)
        raise UnbalancedBlockError, "Unable to find matching opening for {{/#{closer_name}}}" if closer_name != test.name

        contents ||= TemplateNode.new([])

        # closer == test, we reuse that call node
        if alternate
          BlockExpressionNodeWithElse.new([test], contents, test, alternate)
        else
          BlockExpressionNode.new([test], contents, test)
        end
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
      clause('raw') { |raw| raw }
      clause('COMMENT') { |comment_string| CommentNode.new(comment_string) }
    end

    production(:raw) do
      clause('RAWST OUT RAWE') { |_, output_string, _| RawNode.new(OutputNode.new(output_string)) }
    end

    production(:expression) do
      clause('block_expression') { |e| e }
      clause('expr')          { |e| ExpressionNode.new(e) }
      clause('expr_safe')     { |e| SafeExpressionNode.new(e) }
    end

    production(:block_expression) do
      clause('expr_bl_start template EXPRELSE template expr_bl_end') { |test, contents, _, alternate, closer_name| make_block_node(test, contents, alternate, closer_name) }
      clause('expr_bl_start template expr_bl_end') { |test, contents, closer_name| make_block_node(test, contents, nil, closer_name) }
      clause('expr_bl_inv_start template EXPRELSE template expr_bl_end') { |test, alternate, _, contents, closer_name| make_block_node(test, contents, alternate, closer_name) }
      clause('expr_bl_inv_start template expr_bl_end') { |test, alternate, closer_name| make_block_node(test, nil, alternate, closer_name) }
    end

    production(:expr) do
      clause('EXPRST expression_contents EXPRE') { |_,e,_| e }
    end

    production(:expr_safe) do
      clause('TEXPRST expression_contents TEXPRE') { |_,e,_| e }
      clause('EXPRSTAMP expression_contents EXPRE') { |_,e,_| e }
    end

    production(:expr_bl_start) do
      clause('EXPRSTHASH IDENT EXPRE') { |_,e,_| CallNode.new(e,[]) }
      clause('EXPRSTHASH IDENT WHITE arguments EXPRE') { |_,e,_,a,_| CallNode.new(e,a) }
    end

    production(:expr_bl_inv_start) do
      clause('EXPRSTHAT IDENT EXPRE') { |_,e,_| CallNode.new(e,[]) }
      clause('EXPRSTHAT IDENT WHITE arguments EXPRE') { |_,e,_,a,_| CallNode.new(e,a) }
    end

    production(:expr_bl_end) do
      clause('EXPRSTFWSL IDENT EXPRE') { |_,e,_| e }
    end

    production(:expression_contents) do
      clause('call') { |e| e }
      clause('local') { |e| [e] }
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
