# Shared seed vocabulary for the public dashboard ("sinaleira").
# Prefer multi-word / named entities that appear in gaúcho news without noisy unigrams.
# Loaded by db/seeds.rb and coverage specs.
module SeedKeywords
  SECTIONS = {
    "temas" => {
      title: "Temas monitorados",
      description: "Pautas genéricas de gestão pública, segurança, habitação e reconstrução.",
      legend: [
        "Cor: baseada no humor",
        "Ponto de atenção: humor mediano ≥ 60, ou relevância ≥ 70 com as duas lentes negativas"
      ]
    },
    "spgg_equipe" => {
      title: "SPGG — secretária, adjunto e subsecretarias",
      description: "Danielle Calazans, Felipe Cruzeiro e as subsecretarias com seus titulares.",
      legend: [
        "Cor: baseada no humor",
        "Ponto de atenção: humor mediano ≥ 60, ou relevância ≥ 70 com as duas lentes negativas"
      ]
    }
  }.freeze

  TEMAS = [
    [ "palácio piratini", %w[palacio\ piratini] ],
    [ "assembleia legislativa", %w[alers assembleia\ gaúcha assembléia\ legislativa] ],
    [ "eficiência na gestão", %w[gestão\ eficiente eficiencia\ na\ gestao gestão\ pública gestão\ governamental acordo\ de\ resultados] ],
    [ "governo digital", %w[gov.br transformação\ digital governo\ eletrônico digitalização serviços\ digitais] ],
    [ "modernização administrativa", %w[modernização\ do\ estado modernizacao\ administrativa transformação\ administrativa] ],
    [ "criminalidade", %w[segurança\ pública índices\ de\ criminalidade violência\ urbana] ],
    [ "brigada militar", %w[brigada\ militar bm\ rs] ],
    [ "polícia civil", %w[policia\ civil pc\ rs] ],
    [ "homicídios", %w[homicídio homicidios feminicídio feminicidio assassinato] ],
    [ "tráfico de drogas", %w[tráfico\ de\ drogas trafico\ de\ drogas apreensão\ de\ drogas] ],
    [ "entrega de casas", %w[entrega\ de\ moradias entrega\ de\ unidades habitacionais casas\ populares moradias\ populares] ],
    [ "habitação", %w[habitação\ de\ interesse\ social minha\ casa\ minha\ vida programa\ habitacional política\ habitacional] ],
    [ "funrigs", %w[funrigs fundo\ de\ reconstrução fundo\ gaúcho\ de\ reconstrução] ],
    [ "reconstrução do RS", %w[reconstrução\ do\ rs reconstrução\ do\ rio\ grande reconstrução\ gaúcha plano\ de\ reconstrução] ],
    [ "enchentes", %w[enchente enchentes cheia cheias inundação inundações] ],
    [ "defesa civil", %w[defesa\ civil aviso\ da\ defesa\ civil] ],
    [ "dívida pública RS", %w[dívida\ do\ estado dívida\ com\ a\ união renegociação\ da\ dívida\ do\ estado] ],
    [ "plano plurianual", %w[ppa plano\ plurianual orçamento\ plurianual] ],
    [ "parcerias público-privadas", %w[ppp parceria\ público-privada parcerias\ publico-privadas] ],
    [ "concurso público RS", %w[concurso\ público concurso\ estadual edital\ de\ concurso] ],
    [ "servidores estaduais", %w[servidor\ estadual servidores\ do\ estado funcionários\ públicos\ estaduais] ]
  ].freeze

  SPGG_EQUIPE = [
    [ "danielle calazans", %w[danielle\ calazans secretária\ danielle calazans\ spgg] ],
    [ "felipe cruzeiro", %w[felipe\ cruzeiro secretário\ adjunto\ felipe cruzeiro\ spgg] ],
    [ "spgg", %w[secretaria\ de\ planejamento\ governança\ e\ gestão secretaria\ de\ planejamento planejamento\ governança\ e\ gestão spgg\ rs] ],
    [ "suplan", %w[suplan subsecretaria\ de\ planejamento carolina\ mór\ scarparo carolina\ mor\ scarparo carolina\ scarparo scarparo] ],
    [ "suad", %w[suad subsecretaria\ de\ administração liége\ nadir\ pascotini\ dresch liege\ dresch liége\ dresch pascotini\ dresch] ],
    [ "sugep", %w[sugep subsecretaria\ de\ gestão\ e\ desenvolvimento\ de\ pessoas paula\ caffarate caffarate] ],
    [ "spe", %w[spe\ spgg subsecretaria\ de\ patrimônio\ do\ estado patrimônio\ do\ estado vinícius\ oliveira\ braz\ deprá vinicius\ depra vinícius\ deprá deprá] ],
    [ "celic", %w[celic administração\ central\ de\ licitações subsecretaria\ da\ administração\ central\ de\ licitações paulo\ roberto\ sbaraini\ lunardi paulo\ lunardi sbaraini\ lunardi lunardi] ],
    [ "sti spgg", %w[subsecretaria\ de\ governança\ e\ estratégia\ de\ tic subsecretaria\ de\ tic governança\ e\ estratégia\ de\ tic nielson\ luis\ de\ paula\ carramilo nielson\ carramilo carramilo] ]
  ].freeze

  LIST = (TEMAS + SPGG_EQUIPE).freeze

  def self.section_for(term)
    return "spgg_equipe" if SPGG_EQUIPE.any? { |entry_term, _| entry_term == term }

    "temas"
  end

  def self.each_with_section
    TEMAS.each { |term, synonyms| yield term, synonyms, "temas" }
    SPGG_EQUIPE.each { |term, synonyms| yield term, synonyms, "spgg_equipe" }
  end
end
