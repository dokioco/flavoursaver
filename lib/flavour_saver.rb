require "flavour_saver/version"

module FlavourSaver
  class UnknownNodeTypeException < StandardError; end
  class UnknownContextException < StandardError; end
  class InappropriateUseOfElseException < StandardError; end
  class UndefinedPrivateVariableException < StandardError; end
  class UnknownHelperException < RuntimeError; end

  autoload :Lexer,          'flavour_saver/lexer'
  autoload :Parser,         'flavour_saver/parser'
  autoload :Runtime,        'flavour_saver/runtime'
  autoload :Helpers,        'flavour_saver/helpers'
  autoload :NodeCollection, 'flavour_saver/node_collection'

  if defined? Rails
    @default_logger = proc { Rails.logger }
  else
    @default_logger = proc { Logger.new }
  end

  module_function

  def lex(template)
    Lexer.lex(template)
  end

  def parse(tokens)
    Parser.parse(tokens)
  end

  def evaluate(template,context)
    Runtime.run(parse(lex(template)), context)
  end

  def evaluate_file(template_path, context)
    evaluate(File.read(template_path), context)
  end

  def register_helper(*args,&b)
    Helpers.register_helper(*args,&b)
  end

  def reset_helpers
    Helpers.reset_helpers
  end

  def logger
    @logger || @default_logger.call
  end

  def logger=(logger)
    @logger=logger
  end
end
