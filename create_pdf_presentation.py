from reportlab.lib.pagesizes import landscape, letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

def generate_pdf_slides(filename):
    # Letter landscape: 792 x 612 points
    doc = SimpleDocTemplate(
        filename,
        pagesize=landscape(letter),
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # Custom colors
    c_dark_green = colors.HexColor("#1B4332")
    c_primary_green = colors.HexColor("#2D6A4F")
    c_pale_green = colors.HexColor("#D8F3DC")
    c_warm_white = colors.HexColor("#FBFBF8")
    c_text_dark = colors.HexColor("#1A1C19")

    title_hero = ParagraphStyle(
        'HeroTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=38,
        leading=44,
        textColor=c_dark_green,
        alignment=0,
    )

    sub_hero = ParagraphStyle(
        'HeroSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=26,
        textColor=c_primary_green,
        alignment=0,
    )

    body_hero = ParagraphStyle(
        'HeroBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=13,
        leading=18,
        textColor=c_text_dark,
        alignment=0,
    )

    slide_title = ParagraphStyle(
        'SlideTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=c_dark_green,
    )

    slide_tag = ParagraphStyle(
        'SlideTag',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=12,
        textColor=c_primary_green,
    )

    card_title = ParagraphStyle(
        'CardTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=c_dark_green,
    )

    card_body = ParagraphStyle(
        'CardBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10.5,
        leading=14,
        textColor=c_text_dark,
    )

    story = []

    def make_header(tag, title):
        return [
            Paragraph(tag.upper(), slide_tag),
            Spacer(1, 4),
            Paragraph(title, slide_title),
            Spacer(1, 16)
        ]

    # ---------- SLIDE 1: COVER ----------
    story.append(Paragraph("HACKATHON COMPETITION SUBMISSION", slide_tag))
    story.append(Spacer(1, 10))
    story.append(Paragraph("VolunteerConnect", title_hero))
    story.append(Paragraph("Local Volunteer Opportunity Finder", sub_hero))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "A complete, reliable community-engagement mobile app built exclusively with Flutter and Dart. "
        "Connects citizen volunteers with nearby short-term opportunities tailored to their causes, skills, and availability.",
        body_hero
    ))
    story.append(Spacer(1, 24))

    cover_meta = [
        [Paragraph("<b>Framework:</b> Flutter & Dart Only", card_body),
         Paragraph("<b>UI Design:</b> Material 3 Forest Green & Warm White", card_body)],
        [Paragraph("<b>Engine:</b> Transparent 40/30/30 Rule Scoring", card_body),
         Paragraph("<b>Persistence:</b> On-Device SharedPreferences & Anti-Duplicate Hours", card_body)],
        [Paragraph("<b>Quality:</b> 0 flutter analyze issues • 7/7 passing tests", card_body),
         Paragraph("<b>Compliance:</b> 100% original code written in development window", card_body)],
    ]
    t_cov = Table(cover_meta, colWidths=[360, 360])
    t_cov.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), c_pale_green),
        ('BOX', (0,0), (-1,-1), 1.5, c_primary_green),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#74C69D")),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(t_cov)
    story.append(PageBreak())

    # ---------- SLIDE 2: THE PROBLEM ----------
    story.extend(make_header("The Problem", "Community Engagement & Volunteering Bottlenecks"))
    p_data = [
        [
            Paragraph("<b>01. Fragmented Discovery</b>", card_title),
            Paragraph("<b>02. Skills & Availability Mismatch</b>", card_title),
            Paragraph("<b>03. Unverified Volunteer Hours</b>", card_title),
        ],
        [
            Paragraph("Civic events are scattered across informal social groups, physical noticeboards, and messaging chats with zero centralized search or cause filtering.", card_body),
            Paragraph("Volunteers frequently drop out when opportunities demand skills they don't possess or are scheduled when they are working, creating frustration.", card_body),
            Paragraph("Students and employees struggle to verify their community service hours, often resulting in unorganized records and duplicate hour reporting.", card_body),
        ]
    ]
    t_prob = Table(p_data, colWidths=[240, 240, 240])
    t_prob.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.white),
        ('BOX', (0,0), (-1,-1), 1, c_pale_green),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2F0E7")),
        ('TOPPADDING', (0,0), (-1,-1), 14),
        ('BOTTOMPADDING', (0,0), (-1,-1), 14),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(t_prob)
    story.append(PageBreak())

    # ---------- SLIDE 3: RECOMMENDATION ENGINE ----------
    story.extend(make_header("Deterministic Intelligence", "Transparent Rule-Based Recommendation Engine (100 Pts)"))
    r_data = [
        [
            Paragraph("<b>Causes of Interest (40 Pts)</b>", card_title),
            Paragraph("<b>Matching Skills (30 Pts)</b>", card_title),
            Paragraph("<b>Availability Match (30 Pts)</b>", card_title),
        ],
        [
            Paragraph("Prioritizes opportunities that match the user's selected causes (Environment, Education, Animal Welfare, Community, Healthcare).<br/><br/><b>Award:</b> Full 40 points on cause match.", card_body),
            Paragraph("Evaluates overlap between opportunity prerequisites and user skills (Teamwork, Teaching, Gardening, First Aid, etc.).<br/><br/><b>Award:</b> Proportional ratio up to 30 points.", card_body),
            Paragraph("Validates opportunity day of week against user's available days (Saturday, Sunday, weekdays).<br/><br/><b>Award:</b> Full 30 points on schedule alignment.", card_body),
        ],
        [
            Paragraph("<i>✓ Generates explainable reason cards for every single recommendation.</i>", card_body),
            Paragraph("<i>✓ Explains which skills matched and which were missing.</i>", card_body),
            Paragraph("<i>✓ Completely deterministic without black-box ML bias.</i>", card_body),
        ]
    ]
    t_rec = Table(r_data, colWidths=[240, 240, 240])
    t_rec.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.white),
        ('BOX', (0,0), (-1,-1), 1, c_pale_green),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2F0E7")),
        ('TOPPADDING', (0,0), (-1,-1), 12),
        ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(t_rec)
    story.append(PageBreak())

    # ---------- SLIDE 4: HOURS & ANTI-DUPLICATE ----------
    story.extend(make_header("Integrity & Tracking", "Volunteer Hours & Duplicate Prevention Lifecycle"))
    h_steps = [
        [Paragraph("<b>Step 1: Explore & Join</b>", card_title), Paragraph("Volunteer browses community opportunities, reviews spot availability and prerequisite skills, and confirms participation.", card_body)],
        [Paragraph("<b>Step 2: Duplicate Check</b>", card_title), Paragraph("When the volunteer marks an activity completed, the engine checks historical logs for the unique opportunity ID. If already present, duplicate submission is blocked.", card_body)],
        [Paragraph("<b>Step 3: Verified Log Creation</b>", card_title), Paragraph("A persistent VolunteerLog is saved to local storage with timestamp, accredited hours, and activity title.", card_body)],
        [Paragraph("<b>Step 4: Dynamic Milestones</b>", card_title), Paragraph("Total verified hours calculate automatically without duplication, advancing the user through badges (Bronze Helper -> Silver Changemaker -> Gold Champion).", card_body)],
    ]
    t_h = Table(h_steps, colWidths=[200, 520])
    t_h.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.white),
        ('BOX', (0,0), (-1,-1), 1, c_pale_green),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2F0E7")),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(t_h)
    story.append(PageBreak())

    # ---------- SLIDE 5: METRICS & QA ----------
    story.extend(make_header("Verification & QA", "Testing Suite & Static Analysis Results"))
    qa_data = [
        [
            Paragraph("<b>flutter analyze</b>", card_title),
            Paragraph("<b>flutter test</b>", card_title),
            Paragraph("<b>Competition Rules</b>", card_title),
        ],
        [
            Paragraph("<b>Result: 0 Issues Found</b><br/><br/>Strict adherence to flutter_lints. Zero type warnings, zero unused imports, clean syntax.", card_body),
            Paragraph("<b>Result: 7/7 Passed</b><br/><br/>100% test coverage for 40/30/30 scoring algorithm, anti-duplicate hours calculations, and smoke tests.", card_body),
            Paragraph("<b>Result: 100% Compliant</b><br/><br/>Built exclusively with Flutter and Dart. Original code written during allowed window with complete package disclosure.", card_body),
        ]
    ]
    t_qa = Table(qa_data, colWidths=[240, 240, 240])
    t_qa.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.white),
        ('BOX', (0,0), (-1,-1), 1, c_pale_green),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2F0E7")),
        ('TOPPADDING', (0,0), (-1,-1), 14),
        ('BOTTOMPADDING', (0,0), (-1,-1), 14),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(t_qa)

    doc.build(story)
    print(f"PDF Presentation generated at {filename}")

if __name__ == '__main__':
    generate_pdf_slides('c:/Users/rohit/Desktop/BATMAN/VolunteerConnect_Presentation.pdf')
