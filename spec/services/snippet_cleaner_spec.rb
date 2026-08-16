require "rails_helper"

RSpec.describe SnippetCleaner do
  it "strips img tags and other html from rss summaries" do
    raw = <<~HTML
      <img src="https://s2-g1.glbimg.com/example.jpg" /><br />
      Polícia Civil prende suspeito em Porto Alegre.
    HTML

    expect(described_class.call(raw)).to eq("Polícia Civil prende suspeito em Porto Alegre.")
  end

  it "returns blank for image-only snippets" do
    expect(described_class.call('<img src="https://example.com/a.jpg" /><br />')).to eq("")
  end
end
