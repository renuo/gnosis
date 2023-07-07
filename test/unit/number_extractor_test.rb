require_relative '../test_helper'

class NumberExtractorTest < Minitest::Test
  def extract_number_from_ref(params)
    NumberExtractor.call(pull_request: params)
  end

  def test_ticket_is_matched
    numbers = extract_number_from_ref(
      head: {
        ref: 'feature/1-some-feature'
      })
    assert_equal '1', numbers
  end

  def test_no_ticket_is_matched
    numbers = extract_number_from_ref(
      head: {
        ref: 'feature/some-feature'
      })
    assert_nil numbers
  end

  def test_two_tickets_are_matched
    numbers = extract_number_from_ref(
      head: {
        ref: 'feature/1/2/3'
      })
    assert_equal '1', numbers
  end


  def test_ticket_is_matched_in_body
    numbers = extract_number_from_ref(
      body: 'here is some\n\nTICKET-1stuff')
    assert_equal '1', numbers
  end

  def test_ticket_number_in_ref_has_precedence_over_body
    numbers = extract_number_from_ref(
      head: {
        ref: 'feature/1-some-feature'
      },
      body: 'here is some\n\nTICKET-2stuff')
    assert_equal '1', numbers
  end
end
