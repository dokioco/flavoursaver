require 'flavour_saver/lexer'

describe FlavourSaver::Lexer do
  it 'is an RLTK lexer' do
    subject.should be_a(RLTK::Lexer)
  end

  describe 'Tokens' do
    describe 'Expressions' do
      describe '{{foo}}' do
        subject { FlavourSaver::Lexer.lex "{{foo}}" }

        it 'begins with an EXPRST' do
          subject.first.type.should == :EXPRST
        end

        it 'ends with an EXPRE' do
          subject[-2].type.should == :EXPRE
        end

        it 'contains only the identifier "foo"' do
          subject[1..-3].size.should == 1
          subject[1].type.should == :IDENT
          subject[1].value.should == 'foo'
        end
      end

      describe '{{foo bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo bar}}" }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRST, :IDENT, :WHITE, :IDENT, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar' ]
        end
      end

      describe '{{foo "bar"}}' do
        subject { FlavourSaver::Lexer.lex "{{foo \"bar\"}}" }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRST, :IDENT, :WHITE, :STRING, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar' ]
        end
      end

      describe '{{foo bar="baz" hello="goodbye"}}' do
        subject { FlavourSaver::Lexer.lex '{{foo bar="baz" hello="goodbye"}}' }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRST, :IDENT, :WHITE, :IDENT, :EQ, :STRING, :WHITE, :IDENT, :EQ, :STRING, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar', 'baz', 'hello', 'goodbye' ]
        end

      end
    end

    describe '{{else}}' do
      subject { FlavourSaver::Lexer.lex '{{else}}' }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [ :EXPRELSE, :EOS ]
      end
    end

    describe 'Object path expressions' do
      describe '{{foo.bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo.bar}}" }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRST, :IDENT, :DOT, :IDENT, :EXPRE, :EOS ]
        end

        it 'has the correct values' do
          subject.map(&:value).compact.should == ['foo', 'bar']
        end
      end

      describe '{{foo.[10].bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo.[10].bar}}" }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRST, :IDENT, :DOT, :LITERAL, :DOT, :IDENT, :EXPRE, :EOS ]
        end

        it 'has the correct values' do
          subject.map(&:value).compact.should == ['foo', '10', 'bar']
        end
      end

      describe '{{foo.[he!@#$(&@klA)].bar}}' do
        subject { FlavourSaver::Lexer.lex '{{foo.[he!@#$(&@klA)].bar}}' }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRST, :IDENT, :DOT, :LITERAL, :DOT, :IDENT, :EXPRE, :EOS ]
        end

        it 'has the correct values' do
          subject.map(&:value).compact.should == ['foo', 'he!@#$(&@klA)', 'bar']
        end
      end
    end

    describe 'Triple-stash expressions' do
      subject { FlavourSaver::Lexer.lex "{{{foo}}}" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [ :TEXPRST, :IDENT, :TEXPRE, :EOS ]
      end
    end

    describe 'Comment expressions' do
      subject { FlavourSaver::Lexer.lex "{{! WAT}}" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [ :COMMENT, :EOS ]
      end
    end

    describe 'Backtrack expression' do
      subject { FlavourSaver::Lexer.lex "{{../foo}}" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:EXPRST, :DOTDOTSLASH, :IDENT, :EXPRE, :EOS]
      end
    end

    describe 'Carriage-return and new-lines' do
      subject { FlavourSaver::Lexer.lex "{{foo}}\n{{bar}}\r{{baz}}" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:EXPRST,:IDENT,:EXPRE,:OUT,:EXPRST,:IDENT,:EXPRE,:OUT,:EXPRST,:IDENT,:EXPRE,:EOS]
      end
    end

    describe 'Block Expressions' do
      subject { FlavourSaver::Lexer.lex "{{#foo}}{{bar}}{{/foo}}" }

      describe '{{#foo}}{{bar}}{{/foo}}' do
        it 'has tokens in the correct order' do
          subject.map(&:type).should == [
            :EXPRSTHASH, :IDENT, :EXPRE,
            :EXPRST, :IDENT, :EXPRE,
            :EXPRSTFWSL, :IDENT, :EXPRE,
            :EOS
          ]
        end

        it 'has identifiers in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar', 'foo' ]
        end
      end
    end

    describe 'Carriage return' do
      subject { FlavourSaver::Lexer.lex "\r" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT,:EOS]
      end
    end

    describe 'New line' do
      subject { FlavourSaver::Lexer.lex "\n" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT,:EOS]
      end
    end

    describe 'Single curly bracket' do
      subject { FlavourSaver::Lexer.lex "{" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT,:EOS]
      end
    end

    describe 'Mishmash of curlys etc' do
      subject { FlavourSaver::Lexer.lex "asdf { asdf {} { { {{ hello }} }" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT, :EXPRST, :IDENT, :EXPRE, :OUT, :EOS]
      end

      it 'has correct tokens' do
        subject.map(&:value).should == ["asdf { asdf {} { { ", nil, "hello", nil, " }", nil]
      end
    end

    describe 'Complex comment' do
      subject { FlavourSaver::Lexer.lex "asdf {{! alskjd } } alksdjf }} asdf" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT, :COMMENT, :OUT, :EOS]
      end

      it 'has correct tokens' do
        subject.map(&:value).should == ["asdf ", " alskjd } } alksdjf ", " asdf", nil]
      end
    end

    describe 'Zero-length comment' do
      subject { FlavourSaver::Lexer.lex "asdf {{!}} asdf" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT, :OUT, :EOS]
      end

      it 'has correct tokens' do
        subject.map(&:value).should == ["asdf ", " asdf", nil]
      end
    end

    describe 'Zero-length string' do
      subject { FlavourSaver::Lexer.lex "asdf {{\"\"}} asdf" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT, :EXPRST, :STRING, :EXPRE, :OUT, :EOS]
      end

      it 'has correct tokens' do
        subject.map(&:value).should == ["asdf ", nil, '', nil, " asdf", nil]
      end
    end

    describe 'Zero-length single-quote string' do
      subject { FlavourSaver::Lexer.lex "asdf {{''}} asdf" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT, :EXPRST, :S_STRING, :EXPRE, :OUT, :EOS]
      end

      it 'has correct tokens' do
        subject.map(&:value).should == ["asdf ", nil, '', nil, " asdf", nil]
      end
    end

    describe 'Zero-length literal' do
      subject { FlavourSaver::Lexer.lex "asdf {{[]}} asdf" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [:OUT, :EXPRST, :LITERAL, :EXPRE, :OUT, :EOS]
      end

      it 'has correct tokens' do
        subject.map(&:value).should == ["asdf ", nil, '', nil, " asdf", nil]
      end
    end

    context "literals" do
      [
        ["''", :S_STRING, ''],
        ['""', :STRING, '' ],
        ["'squote'", :S_STRING, 'squote'],
        ['"dquote"', :STRING, 'dquote'],
        ["0", :NUMBER, "0"],
        ["1", :NUMBER, "1"],
        ["12345", :NUMBER, "12345"],
        ["-12345", :NUMBER, "-12345"],
        ["1.5", :NUMBER, "1.5"],
        ["-1.5", :NUMBER, "-1.5"],
        ["true", :BOOL, true],
        ["false", :BOOL, false],
      ].each do |input, output_type, output_value|
        context "#{input.inspect}" do
          subject { FlavourSaver::Lexer.lex "asdf {{#{input}}} asdf" }

          it 'has tokens in the correct order' do
            subject.map(&:type).should == [:OUT, :EXPRST, output_type, :EXPRE, :OUT, :EOS]
          end

          it 'has correct tokens' do
            subject.map(&:value).should == ["asdf ", nil, output_value, nil, " asdf", nil]
          end
        end
      end
    end
  end
end
