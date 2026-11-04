from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.lib.utils import simpleSplit


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "diagramas-horta.pdf"
PAGE = landscape(A4)
W, H = PAGE

SAGE = colors.HexColor("#97BA7F")
YELLOW = colors.HexColor("#FFE04E")
CORAL = colors.HexColor("#F9998D")
PEACH = colors.HexColor("#F6A882")
INK = colors.HexColor("#23352B")
MUTED = colors.HexColor("#637269")
PALE = colors.HexColor("#F8F8F3")
LINE = colors.HexColor("#CAD4C9")
GREEN_PALE = colors.HexColor("#EDF4E9")
YELLOW_PALE = colors.HexColor("#FFF7CD")
CORAL_PALE = colors.HexColor("#FFF0ED")


def text(c, value, x, y, size=10, font="Helvetica", color=INK, align="left"):
    c.setFont(font, size)
    c.setFillColor(color)
    if align == "center":
        c.drawCentredString(x, y, value)
    elif align == "right":
        c.drawRightString(x, y, value)
    else:
        c.drawString(x, y, value)


def wrapped(c, value, x, top, width, size=10, leading=13, font="Helvetica", color=INK):
    lines = []
    for paragraph in value.split("\n"):
        lines.extend(simpleSplit(paragraph, font, size, width) or [""])
    c.setFont(font, size)
    c.setFillColor(color)
    for i, line in enumerate(lines):
        c.drawString(x, top - i * leading, line)
    return top - len(lines) * leading


def header(c, number, title, subtitle):
    c.setFillColor(PALE)
    c.rect(0, 0, W, H, stroke=0, fill=1)
    c.setFillColor(SAGE)
    c.rect(0, H - 58, W, 58, stroke=0, fill=1)
    c.setFillColor(YELLOW)
    c.circle(31, H - 29, 16, stroke=0, fill=1)
    text(c, str(number), 31, H - 34, 13, "Helvetica-Bold", INK, "center")
    text(c, title, 61, H - 25, 19, "Helvetica-Bold", colors.white)
    text(c, subtitle, 62, H - 43, 8.8, "Helvetica", colors.white)


def footer(c, page):
    c.setStrokeColor(LINE)
    c.setLineWidth(.7)
    c.line(30, 25, W - 30, 25)
    text(c, "Horta - Modelagem UML", 30, 12, 8, color=MUTED)
    text(c, f"Pagina {page}", W - 30, 12, 8, color=MUTED, align="right")


def rounded(c, x, y, width, height, fill=colors.white, stroke=LINE, radius=10, line_width=.8):
    c.setFillColor(fill)
    c.setStrokeColor(stroke)
    c.setLineWidth(line_width)
    c.roundRect(x, y, width, height, radius, stroke=1, fill=1)


def arrow(c, x1, y1, x2, y2, color=INK, label=None, dash=None, label_offset=5):
    c.saveState()
    c.setStrokeColor(color)
    c.setFillColor(color)
    c.setLineWidth(1)
    if dash:
        c.setDash(dash)
    c.line(x1, y1, x2, y2)
    if dash:
        c.setDash()
    import math
    angle = math.atan2(y2 - y1, x2 - x1)
    head = 7
    c.line(x2, y2, x2 - head * math.cos(angle - .43), y2 - head * math.sin(angle - .43))
    c.line(x2, y2, x2 - head * math.cos(angle + .43), y2 - head * math.sin(angle + .43))
    c.restoreState()
    if label:
        text(c, label, (x1 + x2) / 2, (y1 + y2) / 2 + label_offset, 7.2, color=color, align="center")


def relation(c, x1, y1, x2, y2, left_multi, right_multi, label=None, composition=False):
    c.saveState()
    c.setStrokeColor(INK)
    c.setFillColor(INK)
    c.setLineWidth(.8)
    c.line(x1, y1, x2, y2)
    if composition:
        diamond = [(x1, y1), (x1 + 7, y1 + 5), (x1 + 14, y1), (x1 + 7, y1 - 5)]
        p = c.beginPath()
        p.moveTo(*diamond[0])
        for point in diamond[1:]:
            p.lineTo(*point)
        p.close()
        c.drawPath(p, stroke=1, fill=1)
    else:
        arrow(c, x1, y1, x2, y2)
    c.restoreState()
    text(c, left_multi, x1 + 5, y1 + 6, 6.6, color=MUTED)
    text(c, right_multi, x2 - 5, y2 + 6, 6.6, color=MUTED, align="right")
    if label:
        text(c, label, (x1 + x2) / 2, (y1 + y2) / 2 + 7, 6.6, color=MUTED, align="center")


def actor(c, x, y, label):
    c.setStrokeColor(INK)
    c.setLineWidth(1.1)
    c.circle(x, y + 18, 7, stroke=1, fill=0)
    c.line(x, y + 11, x, y - 10)
    c.line(x - 10, y + 3, x + 10, y + 3)
    c.line(x, y - 10, x - 9, y - 23)
    c.line(x, y - 10, x + 9, y - 23)
    for index, line in enumerate(simpleSplit(label, "Helvetica-Bold", 8, 86)):
        text(c, line, x, y - 37 - index * 10, 8, "Helvetica-Bold", INK, "center")


def usecase(c, x, y, width, height, label, fill=colors.white):
    c.setFillColor(fill)
    c.setStrokeColor(SAGE)
    c.setLineWidth(.9)
    c.ellipse(x, y, x + width, y + height, stroke=1, fill=1)
    lines = simpleSplit(label, "Helvetica-Bold", 8.5, width - 20)
    for index, line in enumerate(lines):
        text(c, line, x + width / 2, y + height / 2 + (len(lines) - 1) * 5 - index * 10, 8.5, "Helvetica-Bold", INK, "center")


def page_use_cases(c):
    header(c, 1, "Diagrama de casos de uso", "Atores e interacoes do aplicativo Horta")
    c.setStrokeColor(SAGE)
    c.setLineWidth(1.1)
    c.roundRect(166, 63, 505, 444, 14, stroke=1, fill=0)
    text(c, "Aplicativo Horta", 184, 490, 11, "Helvetica-Bold", SAGE)

    actor(c, 81, 414, "Jardineiro")
    actor(c, 81, 246, "Camera do\ndispositivo")
    actor(c, 759, 320, "Servico externo\nde IA")
    actor(c, 759, 123, "Servico de\nnotificacoes")

    nodes = {
        "dashboard": (210, 405, 130, 43, "Consultar painel\nda horta", GREEN_PALE),
        "plants": (210, 327, 130, 43, "Gerenciar\nplantas", colors.white),
        "details": (210, 247, 130, 43, "Consultar detalhes\nda planta", colors.white),
        "care": (210, 165, 130, 43, "Registrar cuidado\nrealizado", YELLOW_PALE),
        "guide": (455, 405, 130, 43, "Consultar guia\nde cuidados", colors.white),
        "scan": (455, 327, 130, 43, "Escanear\nfolha", YELLOW_PALE),
        "diagnose": (455, 247, 130, 43, "Diagnosticar saude\nda planta", CORAL_PALE),
        "save": (455, 165, 130, 43, "Salvar\ndiagnostico", CORAL_PALE),
        "config": (455, 89, 130, 43, "Configurar\nlembretes", colors.white),
        "receive": (260, 89, 130, 43, "Receber lembrete\nde cuidado", colors.white),
    }
    for _, (x, y, width, height, label, fill) in nodes.items():
        usecase(c, x, y, width, height, label, fill)

    # Jardineiro associations
    c.setStrokeColor(MUTED)
    c.setLineWidth(.65)
    source_x, source_y = 99, 417
    for destination in [(210, 426), (210, 348), (210, 268), (210, 186), (455, 426), (455, 348), (455, 186), (455, 110), (260, 110)]:
        c.line(source_x, source_y, *destination)
    c.line(99, 250, 455, 348)
    c.line(741, 323, 585, 268)
    c.line(741, 126, 390, 110)
    arrow(c, 520, 327, 520, 290, SAGE, "inclui", dash=[2, 2])
    arrow(c, 520, 247, 520, 208, SAGE, "inclui", dash=[2, 2])

    text(c, "Associacao", 186, 78, 7.5, color=MUTED)
    c.setStrokeColor(MUTED)
    c.setLineWidth(.65)
    c.line(244, 81, 275, 81)
    c.setDash(2, 2)
    c.setStrokeColor(SAGE)
    c.line(310, 81, 340, 81)
    c.setDash()
    text(c, "Relacao <<inclui>>", 347, 78, 7.5, color=MUTED)
    footer(c, 1)
    c.showPage()


def table_row(c, x, y_top, label, value, width=782, label_width=174, min_height=26, fill=colors.white):
    value_lines = simpleSplit(value, "Helvetica", 8.6, width - label_width - 16)
    height = max(min_height, 13 + len(value_lines) * 11)
    c.setFillColor(fill)
    c.setStrokeColor(LINE)
    c.setLineWidth(.6)
    c.rect(x, y_top - height, width, height, stroke=1, fill=1)
    c.setFillColor(GREEN_PALE)
    c.rect(x, y_top - height, label_width, height, stroke=0, fill=1)
    c.setStrokeColor(LINE)
    c.line(x + label_width, y_top - height, x + label_width, y_top)
    text(c, label, x + 9, y_top - 17, 8.4, "Helvetica-Bold", INK)
    wrapped(c, value, x + label_width + 9, y_top - 14, width - label_width - 16, 8.6, 11, color=INK)
    return y_top - height


def page_critical_use_case(c):
    header(c, 2, "Caso de uso critico: diagnosticar planta", "UC-07 - analise de saude por imagem")
    x = 30
    y = 514
    rows = [
        ("Objetivo", "Identificar a planta e possiveis deficiencias em uma folha fotografada e oferecer orientacoes de cuidado."),
        ("Ator primario", "Jardineiro"),
        ("Atores de apoio", "Camera do dispositivo e Servico externo de IA."),
        ("Gatilho", "O jardineiro toca no botao Escanear folha."),
        ("Pre-condicoes", "Aplicativo aberto; permissao de camera concedida; conexao com a internet para a analise real."),
        ("Pos-condicao de sucesso", "A imagem, o resultado e as recomendacoes ficam associados a planta no historico de diagnosticos."),
        ("Pos-condicao de falha", "Nenhum diagnostico e salvo como concluido; o aplicativo informa o motivo e permite nova tentativa."),
    ]
    for index, (label, value) in enumerate(rows):
        y = table_row(c, x, y, label, value, fill=colors.white if index % 2 == 0 else colors.HexColor("#FBFCF9"))

    text(c, "Fluxo principal de sucesso", 30, y - 28, 14, "Helvetica-Bold", INK)
    steps = [
        "O jardineiro seleciona Escanear folha.",
        "O sistema abre a camera e orienta o enquadramento em boa iluminacao.",
        "O jardineiro captura a imagem e confirma o envio.",
        "O sistema cria o diagnostico Em analise e associa a imagem capturada.",
        "O sistema envia a imagem ao servico externo de IA.",
        "O servico identifica a especie ou confirma a especie selecionada e retorna evidencias.",
        "O sistema registra achados, confianca, severidade e recomendacoes.",
        "O sistema atualiza a situacao de saude da planta e apresenta os proximos cuidados.",
        "O jardineiro salva ou fecha o resultado; o diagnostico permanece no historico.",
    ]
    current = y - 50
    for index, step in enumerate(steps, 1):
        c.setFillColor(YELLOW)
        c.circle(43, current + 3, 9, stroke=0, fill=1)
        text(c, str(index), 43, current, 7.5, "Helvetica-Bold", INK, "center")
        end = wrapped(c, step, 61, current + 4, 718, 9, 12, color=INK)
        current = end - 5
    footer(c, 2)
    c.showPage()


def page_use_case_exceptions(c):
    header(c, 2, "Caso de uso critico: excecoes e regras", "UC-07 - tratamento de cenarios alternativos")
    text(c, "Fluxos alternativos e excecoes", 30, 508, 15, "Helvetica-Bold", INK)
    x = 30
    top = 488
    col = [58, 220, 504]
    headers = ["Codigo", "Situacao", "Resposta do sistema"]
    c.setFillColor(SAGE)
    c.setStrokeColor(SAGE)
    c.rect(x, top - 27, sum(col), 27, stroke=1, fill=1)
    cx = x
    for width, name in zip(col, headers):
        text(c, name, cx + 8, top - 17, 8.6, "Helvetica-Bold", colors.white)
        cx += width
        if cx < x + sum(col):
            c.setStrokeColor(colors.white)
            c.line(cx, top - 27, cx, top)
    alternatives = [
        ("A1", "Permissao da camera negada", "Explica que a camera e necessaria e oferece abrir as configuracoes ou cancelar."),
        ("A2", "Foto sem qualidade suficiente", "Solicita nova foto, indicando iluminacao ou foco insuficientes; nada e enviado para analise."),
        ("A3", "Sem conexao ou IA indisponivel", "Atualiza o diagnostico para Falhou, informa a indisponibilidade e permite tentar novamente."),
        ("A4", "Planta nao identificada", "Exibe resultado inconclusivo e permite selecionar a especie manualmente ou capturar outra imagem."),
        ("A5", "Nenhuma deficiencia detectada", "Salva o diagnostico como Saudavel e mantem a planta nesse estado."),
    ]
    y = top - 27
    for index, (code, situation, response) in enumerate(alternatives):
        lines_s = simpleSplit(situation, "Helvetica", 8.6, col[1] - 16)
        lines_r = simpleSplit(response, "Helvetica", 8.6, col[2] - 16)
        height = max(40, (max(len(lines_s), len(lines_r)) * 11) + 14)
        c.setFillColor(colors.white if index % 2 == 0 else colors.HexColor("#FBFCF9"))
        c.setStrokeColor(LINE)
        c.rect(x, y - height, sum(col), height, stroke=1, fill=1)
        c.line(x + col[0], y - height, x + col[0], y)
        c.line(x + col[0] + col[1], y - height, x + col[0] + col[1], y)
        text(c, code, x + col[0] / 2, y - 19, 8.5, "Helvetica-Bold", CORAL, "center")
        wrapped(c, situation, x + col[0] + 8, y - 13, col[1] - 16, 8.6, 11)
        wrapped(c, response, x + col[0] + col[1] + 8, y - 13, col[2] - 16, 8.6, 11)
        y -= height

    text(c, "Regras de negocio", 30, y - 30, 15, "Helvetica-Bold", INK)
    rules = [
        "Uma imagem pertence a exatamente um diagnostico.",
        "Um diagnostico concluido pertence a exatamente uma planta e pode possuir zero ou mais achados.",
        "Cada achado aponta para uma deficiencia cadastrada e registra severidade e confianca.",
        "O historico de diagnosticos e preservado; cada escaneamento gera uma ocorrencia independente.",
        "O resultado e orientativo e nao substitui acompanhamento agronomico profissional em casos de risco.",
    ]
    rule_y = y - 50
    for rule in rules:
        c.setFillColor(SAGE)
        c.circle(39, rule_y + 2, 3, stroke=0, fill=1)
        end = wrapped(c, rule, 51, rule_y + 5, 720, 9, 12)
        rule_y = end - 4
    footer(c, 3)
    c.showPage()


def class_box(c, x, y, width, height, title, attributes):
    c.setFillColor(colors.white)
    c.setStrokeColor(SAGE)
    c.setLineWidth(.8)
    c.rect(x, y, width, height, stroke=1, fill=1)
    c.setFillColor(GREEN_PALE)
    c.rect(x, y + height - 24, width, 24, stroke=0, fill=1)
    c.setStrokeColor(SAGE)
    c.line(x, y + height - 24, x + width, y + height - 24)
    text(c, title, x + width / 2, y + height - 16, 8.5, "Helvetica-Bold", INK, "center")
    cursor = y + height - 37
    for attribute in attributes:
        text(c, attribute, x + 7, cursor, 7.3, "Helvetica", INK)
        cursor -= 10


def page_domain(c):
    header(c, 3, "Modelo de dominio", "Classes conceituais e multiplicidades")
    positions = {
        "gardener": (28, 412, 154, 88),
        "garden": (230, 412, 154, 88),
        "plant": (432, 412, 154, 88),
        "species": (634, 412, 154, 88),
        "guide": (634, 250, 154, 88),
        "task": (230, 250, 154, 88),
        "diagnosis": (432, 250, 154, 88),
        "image": (230, 88, 154, 88),
        "finding": (432, 88, 154, 88),
        "deficiency": (634, 88, 154, 88),
    }
    classes = {
        "gardener": ("Jardineiro", ["+ id: UUID", "+ nome: String", "+ email: String"]),
        "garden": ("Horta", ["+ id: UUID", "+ nome: String"]),
        "plant": ("Planta", ["+ id: UUID", "+ apelido: String", "+ dataPlantio: Date", "+ statusSaude: StatusSaude"]),
        "species": ("EspeciePlanta", ["+ id: UUID", "+ nomePopular: String", "+ nomeCientifico: String"]),
        "guide": ("GuiaCuidado", ["+ id: UUID", "+ titulo: String", "+ conteudo: String", "+ categoria: TipoCuidado"]),
        "task": ("TarefaCuidado", ["+ id: UUID", "+ tipo: TipoCuidado", "+ previstaPara: DateTime", "+ status: StatusTarefa"]),
        "diagnosis": ("Diagnostico", ["+ id: UUID", "+ realizadoEm: DateTime", "+ status: StatusDiagnostico", "+ observacao: String"]),
        "image": ("ImagemEscaneada", ["+ id: UUID", "+ uri: String", "+ capturadaEm: DateTime"]),
        "finding": ("AchadoDiagnostico", ["+ id: UUID", "+ confianca: Decimal", "+ severidade: Severidade", "+ recomendacao: String"]),
        "deficiency": ("Deficiencia", ["+ id: UUID", "+ nome: String", "+ sintomas: String"]),
    }
    for key, (title, attrs) in classes.items():
        class_box(c, *positions[key], title, attrs)

    # relations are drawn after boxes; paths use clear box edges.
    relation(c, 182, 456, 230, 456, "1", "0..*", "mantem")
    relation(c, 384, 456, 432, 456, "1", "0..*", "contem", composition=True)
    relation(c, 586, 456, 634, 456, "0..*", "1", "e da especie")
    relation(c, 509, 412, 307, 338, "1", "0..*", "possui", composition=True)
    relation(c, 509, 412, 509, 338, "1", "0..*", "historico", composition=True)
    relation(c, 711, 412, 711, 338, "0..*", "0..*", "recomenda")
    relation(c, 509, 250, 307, 176, "1", "1", "origem", composition=True)
    relation(c, 509, 250, 509, 176, "1", "0..*", "produz", composition=True)
    relation(c, 586, 132, 634, 132, "0..*", "1", "aponta para")

    rounded(c, 598, 27, 190, 34, fill=colors.white, radius=7)
    c.setFillColor(INK)
    c.rect(610, 39, 13, 8, stroke=1, fill=1)
    text(c, "Composicao: ciclo de vida dependente", 633, 38, 7.4, color=MUTED)
    text(c, "Multiplicidades aparecem nas extremidades de cada associacao.", 28, 44, 8, color=MUTED)
    footer(c, 4)
    c.showPage()


def participant(c, x, label, fill):
    rounded(c, x - 59, 490, 118, 34, fill=fill, stroke=SAGE, radius=7)
    for index, line in enumerate(simpleSplit(label, "Helvetica-Bold", 8, 102)):
        text(c, line, x, 503 - index * 10, 8, "Helvetica-Bold", INK, "center")
    c.setStrokeColor(MUTED)
    c.setLineWidth(.7)
    c.setDash(3, 3)
    c.line(x, 490, x, 83)
    c.setDash()


def sequence_message(c, x1, x2, y, label, dashed=False, failure=False):
    if failure:
        c.setStrokeColor(CORAL)
        c.setFillColor(CORAL)
    else:
        c.setStrokeColor(INK)
        c.setFillColor(INK)
    c.setLineWidth(1)
    if dashed:
        c.setDash(3, 2)
    c.line(x1, y, x2, y)
    if dashed:
        c.setDash()
    if x2 > x1:
        c.line(x2, y, x2 - 7, y + 3)
        c.line(x2, y, x2 - 7, y - 3)
    else:
        c.line(x2, y, x2 + 7, y + 3)
        c.line(x2, y, x2 + 7, y - 3)
    text(c, label, (x1 + x2) / 2, y + 6, 7.3, color=CORAL if failure else INK, align="center")


def page_sequence(c):
    header(c, 4, "Diagrama de sequencia", "Fluxo de diagnostico envolvendo camera e servico externo")
    participants = [(87, "Jardineiro", YELLOW_PALE), (247, "App Flutter", GREEN_PALE), (407, "Camera do\ndispositivo", YELLOW_PALE), (567, "Repositorio\nde dados", colors.white), (727, "Servico externo\nde IA", CORAL_PALE)]
    for x, label, fill in participants:
        participant(c, x, label, fill)

    sequence_message(c, 87, 247, 450, "Seleciona Escanear folha")
    sequence_message(c, 247, 407, 420, "Solicita permissao e abre camera")
    sequence_message(c, 407, 247, 390, "Retorna foto capturada", dashed=True)
    sequence_message(c, 247, 567, 360, "Cria Diagnostico(Em analise) e salva imagem")
    sequence_message(c, 247, 727, 330, "Envia imagem e especie conhecida (se houver)")

    # alt block
    c.setStrokeColor(SAGE)
    c.setLineWidth(.9)
    c.roundRect(38, 98, 752, 205, 8, stroke=1, fill=0)
    c.setFillColor(GREEN_PALE)
    c.rect(38, 278, 100, 25, stroke=0, fill=1)
    text(c, "alt", 51, 286, 8, "Helvetica-Bold", SAGE)
    text(c, "Analise concluida", 146, 286, 8, "Helvetica-Bold", SAGE)
    sequence_message(c, 727, 247, 260, "Retorna especie, achados, confianca e recomendacoes", dashed=True)
    sequence_message(c, 247, 567, 232, "Salva achados e atualiza Diagnostico(Concluido)")
    sequence_message(c, 247, 567, 205, "Atualiza statusSaude da Planta")
    sequence_message(c, 247, 87, 178, "Exibe diagnostico e proximos cuidados", dashed=True)
    c.setStrokeColor(LINE)
    c.line(39, 159, 790, 159)
    text(c, "else  Foto inconclusiva", 51, 147, 8, "Helvetica-Bold", MUTED)
    sequence_message(c, 727, 247, 133, "Resultado inconclusivo", dashed=True)
    sequence_message(c, 247, 567, 112, "Atualiza Diagnostico(Inconclusivo)")
    sequence_message(c, 247, 87, 92, "Solicita nova foto ou especie manual", dashed=True)
    text(c, "Falha de comunicacao: atualizar Diagnostico(Falhou) e oferecer nova tentativa.", 420, 68, 7.6, "Helvetica-Oblique", CORAL, "center")
    footer(c, 5)
    c.showPage()


def state_node(c, x, y, width, height, label, fill=colors.white):
    rounded(c, x, y, width, height, fill=fill, stroke=SAGE, radius=12)
    lines = simpleSplit(label, "Helvetica-Bold", 9, width - 14)
    for index, line in enumerate(lines):
        text(c, line, x + width / 2, y + height / 2 + (len(lines) - 1) * 5 - index * 10, 9, "Helvetica-Bold", INK, "center")


def page_states(c):
    header(c, 5, "Diagrama de estados: Planta", "Ciclo de vida de uma planta no cultivo")
    state_node(c, 348, 445, 146, 40, "Cadastrada", YELLOW_PALE)
    state_node(c, 348, 354, 146, 48, "Saudavel", GREEN_PALE)
    state_node(c, 105, 252, 160, 48, "Precisa de cuidado", YELLOW_PALE)
    state_node(c, 578, 252, 160, 48, "Em diagnostico", CORAL_PALE)
    state_node(c, 578, 144, 160, 48, "Com deficiencia", CORAL_PALE)
    state_node(c, 348, 144, 160, 48, "Em recuperacao", YELLOW_PALE)
    state_node(c, 77, 74, 136, 40, "Arquivada", colors.white)

    c.setFillColor(INK)
    c.circle(421, 512, 7, stroke=0, fill=1)
    arrow(c, 421, 505, 421, 485, INK, "adicionada ao cultivo", label_offset=4)
    arrow(c, 421, 445, 421, 402, INK, "cadastro concluido", label_offset=4)
    arrow(c, 348, 377, 265, 277, INK, "tarefa vence", label_offset=6)
    arrow(c, 265, 277, 348, 377, INK, "cuidado concluido", label_offset=-10)
    arrow(c, 494, 378, 578, 277, INK, "escaneamento iniciado", label_offset=7)
    arrow(c, 578, 277, 494, 378, INK, "sem deficiencia ou inconclusivo", label_offset=-12)
    arrow(c, 658, 252, 658, 192, INK, "deficiencia identificada", label_offset=5)
    arrow(c, 578, 168, 508, 168, INK, "tratamento registrado", label_offset=7)
    arrow(c, 421, 192, 421, 354, INK, "analise posterior sem deficiencia", label_offset=5)
    arrow(c, 508, 168, 578, 168, INK, "deficiencia persiste", label_offset=-10)
    arrow(c, 348, 377, 213, 94, MUTED, "removida do cultivo", label_offset=5)
    arrow(c, 105, 276, 213, 94, MUTED, None)
    arrow(c, 578, 168, 213, 94, MUTED, None)
    arrow(c, 348, 168, 213, 94, MUTED, None)
    c.setStrokeColor(INK)
    c.setLineWidth(1)
    c.line(77, 94, 53, 94)
    c.setFillColor(INK)
    c.circle(45, 94, 7, stroke=0, fill=1)
    text(c, "A entidade principal e Planta; seu estado de saude muda por tarefas e diagnosticos.", 30, 42, 8, color=MUTED)
    footer(c, 6)
    c.showPage()


def build():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUTPUT), pagesize=PAGE, pageCompression=1)
    c.setTitle("Horta - Modelagem UML")
    c.setAuthor("Codex")
    c.setSubject("Diagramas de casos de uso, dominio, sequencia e estados")
    page_use_cases(c)
    page_critical_use_case(c)
    page_use_case_exceptions(c)
    page_domain(c)
    page_sequence(c)
    page_states(c)
    c.save()
    print(OUTPUT)


if __name__ == "__main__":
    build()
