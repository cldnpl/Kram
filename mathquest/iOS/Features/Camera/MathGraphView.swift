import SwiftUI
import WebKit

struct MathGraphView: View {
    let graphData: GraphData
    @State private var graphHeight: CGFloat = 350

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.purple)
                Text(L10n.graphTitle)
                    .font(.headline)
            }

            MathGraphWebView(graphData: graphData)
                .frame(height: graphHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            GraphInfoCards(graphData: graphData)
        }
    }
}

private struct GraphInfoCards: View {
    let graphData: GraphData

    var body: some View {
        VStack(spacing: 8) {
            if !graphData.domain.isEmpty {
                infoRow(label: L10n.domain, value: graphData.domain)
            }
            if !graphData.range.isEmpty {
                infoRow(label: L10n.range, value: graphData.range)
            }

            let xIntercepts = graphData.intercepts["x"] ?? []
            if !xIntercepts.isEmpty {
                infoRow(label: L10n.xIntercepts, value: xIntercepts.joined(separator: ", "))
            }

            let yIntercepts = graphData.intercepts["y"] ?? []
            if !yIntercepts.isEmpty {
                infoRow(label: L10n.yIntercepts, value: yIntercepts.joined(separator: ", "))
            }

            let vertical = graphData.asymptotes["vertical"] ?? []
            let horizontal = graphData.asymptotes["horizontal"] ?? []
            let oblique = graphData.asymptotes["oblique"] ?? []
            let allAsymptotes = vertical + horizontal + oblique
            if !allAsymptotes.isEmpty {
                infoRow(label: L10n.asymptotes, value: allAsymptotes.joined(separator: ", "))
            }

            if !graphData.criticalPoints.isEmpty {
                let pointsStr = graphData.criticalPoints.map { "(\($0.x), \($0.y)) [\($0.type)]" }
                infoRow(label: L10n.criticalPoints, value: pointsStr.joined(separator: ", "))
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MathGraphWebView: UIViewRepresentable {
    let graphData: GraphData

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateGraphHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateGraphHTML() -> String {
        let expr = graphData.expression
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")

        let verticalAsymptotes = (graphData.asymptotes["vertical"] ?? [])
            .compactMap { extractNumber(from: $0) }
        let horizontalAsymptotes = (graphData.asymptotes["horizontal"] ?? [])
            .compactMap { extractNumber(from: $0) }

        let criticalPointsJS = graphData.criticalPoints.compactMap { cp -> String? in
            guard let xVal = Double(cp.x), let yVal = Double(cp.y) else { return nil }
            let color: String
            switch cp.type {
            case "maximum": color = "#dc2626"
            case "minimum": color = "#16a34a"
            case "inflection": color = "#d97706"
            case "discontinuity": color = "#7c3aed"
            default: color = "#6b7280"
            }
            return "{x:\(xVal),y:\(yVal),type:'\(cp.type)',color:'\(color)'}"
        }.joined(separator: ",")

        let vertAsymJS = verticalAsymptotes.map { String($0) }.joined(separator: ",")
        let horizAsymJS = horizontalAsymptotes.map { String($0) }.joined(separator: ",")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { background: #ffffff; overflow: hidden; }
            canvas { display: block; width: 100%; height: 100%; }
        </style>
        </head>
        <body>
        <canvas id="graph"></canvas>
        <script>
        (function() {
            const canvas = document.getElementById('graph');
            const ctx = canvas.getContext('2d');
            const dpr = window.devicePixelRatio || 1;

            function resize() {
                canvas.width = canvas.clientWidth * dpr;
                canvas.height = canvas.clientHeight * dpr;
                ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
            }
            resize();
            window.addEventListener('resize', resize);

            const W = canvas.clientWidth;
            const H = canvas.clientHeight;

            // View bounds
            let xMin = -10, xMax = 10, yMin = -8, yMax = 8;

            // Adjust view to show critical points
            const critPts = [\(criticalPointsJS)];
            if (critPts.length > 0) {
                const xs = critPts.map(p => p.x).filter(v => isFinite(v));
                const ys = critPts.map(p => p.y).filter(v => isFinite(v));
                if (xs.length > 0) {
                    const cxMin = Math.min(...xs), cxMax = Math.max(...xs);
                    const margin = Math.max(5, (cxMax - cxMin) * 0.5 + 3);
                    xMin = Math.min(xMin, cxMin - margin);
                    xMax = Math.max(xMax, cxMax + margin);
                }
                if (ys.length > 0) {
                    const cyMin = Math.min(...ys), cyMax = Math.max(...ys);
                    const margin = Math.max(4, (cyMax - cyMin) * 0.5 + 3);
                    yMin = Math.min(yMin, cyMin - margin);
                    yMax = Math.max(yMax, cyMax + margin);
                }
            }

            function toScreenX(x) { return (x - xMin) / (xMax - xMin) * W; }
            function toScreenY(y) { return H - (y - yMin) / (yMax - yMin) * H; }

            function evalExpr(x) {
                try {
                    return Function('x', 'Math', 'return ' + '\(expr)')(x, Math);
                } catch(e) { return NaN; }
            }

            // Grid — light gray on white
            function drawGrid() {
                ctx.strokeStyle = '#e5e7eb';
                ctx.lineWidth = 0.5;
                const stepX = niceStep((xMax - xMin) / 8);
                const stepY = niceStep((yMax - yMin) / 6);

                ctx.font = '10px -apple-system, sans-serif';
                ctx.fillStyle = '#000000';
                ctx.textAlign = 'center';

                for (let x = Math.ceil(xMin / stepX) * stepX; x <= xMax; x += stepX) {
                    const sx = toScreenX(x);
                    ctx.beginPath(); ctx.moveTo(sx, 0); ctx.lineTo(sx, H); ctx.stroke();
                    if (Math.abs(x) > 0.001) {
                        ctx.fillText(formatNum(x), sx, toScreenY(0) + 14);
                    }
                }
                ctx.textAlign = 'right';
                for (let y = Math.ceil(yMin / stepY) * stepY; y <= yMax; y += stepY) {
                    const sy = toScreenY(y);
                    ctx.beginPath(); ctx.moveTo(0, sy); ctx.lineTo(W, sy); ctx.stroke();
                    if (Math.abs(y) > 0.001) {
                        ctx.fillText(formatNum(y), toScreenX(0) - 6, sy + 4);
                    }
                }
            }

            function niceStep(rough) {
                const pow10 = Math.pow(10, Math.floor(Math.log10(rough)));
                const frac = rough / pow10;
                if (frac <= 1.5) return pow10;
                if (frac <= 3.5) return 2 * pow10;
                if (frac <= 7.5) return 5 * pow10;
                return 10 * pow10;
            }

            function formatNum(n) {
                return Math.abs(n) >= 1000 ? n.toExponential(0) :
                       Number.isInteger(n) ? n.toString() :
                       n.toFixed(1);
            }

            // Axes — BLACK, bold
            function drawAxes() {
                ctx.strokeStyle = '#000000';
                ctx.lineWidth = 2;
                // X axis
                const y0 = toScreenY(0);
                ctx.beginPath(); ctx.moveTo(0, y0); ctx.lineTo(W, y0); ctx.stroke();
                // Y axis
                const x0 = toScreenX(0);
                ctx.beginPath(); ctx.moveTo(x0, 0); ctx.lineTo(x0, H); ctx.stroke();

                // Axis arrows
                // X arrow
                ctx.beginPath(); ctx.moveTo(W - 2, y0 - 5); ctx.lineTo(W, y0); ctx.lineTo(W - 2, y0 + 5); ctx.stroke();
                // Y arrow
                ctx.beginPath(); ctx.moveTo(x0 - 5, 2); ctx.lineTo(x0, 0); ctx.lineTo(x0 + 5, 2); ctx.stroke();

                // Labels — black
                ctx.fillStyle = '#000000';
                ctx.font = 'bold 13px -apple-system, sans-serif';
                ctx.textAlign = 'left';
                ctx.fillText('x', W - 16, y0 - 8);
                ctx.fillText('y', x0 + 8, 14);
            }

            // Asymptotes — dashed red/blue
            function drawAsymptotes() {
                ctx.setLineDash([6, 4]);
                ctx.lineWidth = 1.5;

                // Vertical — red
                ctx.strokeStyle = '#dc262688';
                [\(vertAsymJS)].forEach(function(xVal) {
                    const sx = toScreenX(xVal);
                    ctx.beginPath(); ctx.moveTo(sx, 0); ctx.lineTo(sx, H); ctx.stroke();
                });

                // Horizontal — blue
                ctx.strokeStyle = '#2563eb88';
                [\(horizAsymJS)].forEach(function(yVal) {
                    const sy = toScreenY(yVal);
                    ctx.beginPath(); ctx.moveTo(0, sy); ctx.lineTo(W, sy); ctx.stroke();
                });

                ctx.setLineDash([]);
            }

            // Function curve — PURPLE (#7c3aed)
            function drawFunction() {
                const vertAsym = [\(vertAsymJS)];
                ctx.strokeStyle = '#7c3aed';
                ctx.lineWidth = 2.5;
                ctx.beginPath();

                const steps = W * 2;
                let drawing = false;
                let prevY = null;

                for (let i = 0; i <= steps; i++) {
                    const x = xMin + (xMax - xMin) * i / steps;
                    const y = evalExpr(x);
                    const sy = toScreenY(y);
                    const sx = toScreenX(x);

                    // Break at vertical asymptotes
                    const nearAsym = vertAsym.some(a => Math.abs(x - a) < (xMax - xMin) / steps * 1.5);

                    if (!isFinite(y) || nearAsym || (prevY !== null && Math.abs(sy - prevY) > H * 0.8)) {
                        ctx.stroke();
                        ctx.beginPath();
                        drawing = false;
                        prevY = null;
                        continue;
                    }

                    if (!drawing) {
                        ctx.moveTo(sx, sy);
                        drawing = true;
                    } else {
                        ctx.lineTo(sx, sy);
                    }
                    prevY = sy;
                }
                ctx.stroke();
            }

            // Critical points
            function drawCriticalPoints() {
                critPts.forEach(function(p) {
                    if (!isFinite(p.x) || !isFinite(p.y)) return;
                    const sx = toScreenX(p.x);
                    const sy = toScreenY(p.y);

                    // Point
                    ctx.beginPath();
                    ctx.arc(sx, sy, 5, 0, Math.PI * 2);
                    ctx.fillStyle = p.color;
                    ctx.fill();
                    ctx.strokeStyle = '#000000';
                    ctx.lineWidth = 1.5;
                    ctx.stroke();

                    // Label — black text
                    ctx.fillStyle = '#000000';
                    ctx.font = '10px -apple-system, sans-serif';
                    ctx.textAlign = 'center';
                    ctx.fillText('(' + formatNum(p.x) + ', ' + formatNum(p.y) + ')', sx, sy - 10);
                });
            }

            // Intercepts
            function drawIntercepts() {
                const xInts = [\(interceptsXJS(graphData: graphData))];
                const yInts = [\(interceptsYJS(graphData: graphData))];

                // X intercepts — orange
                ctx.fillStyle = '#d97706';
                xInts.forEach(function(xVal) {
                    const sx = toScreenX(xVal), sy = toScreenY(0);
                    ctx.beginPath(); ctx.arc(sx, sy, 4, 0, Math.PI * 2); ctx.fill();
                });

                // Y intercepts — blue
                ctx.fillStyle = '#2563eb';
                yInts.forEach(function(yVal) {
                    const sx = toScreenX(0), sy = toScreenY(yVal);
                    ctx.beginPath(); ctx.arc(sx, sy, 4, 0, Math.PI * 2); ctx.fill();
                });
            }

            // Title — black text
            function drawTitle() {
                ctx.fillStyle = '#000000';
                ctx.font = 'bold 13px -apple-system, sans-serif';
                ctx.textAlign = 'left';
                ctx.fillText('f(x) = \(expr.replacingOccurrences(of: "'", with: ""))', 12, 20);
            }

            // Render
            function draw() {
                ctx.fillStyle = '#ffffff';
                ctx.fillRect(0, 0, W, H);
                drawGrid();
                drawAxes();
                drawAsymptotes();
                drawFunction();
                drawIntercepts();
                drawCriticalPoints();
                drawTitle();
            }
            draw();
        })();
        </script>
        </body>
        </html>
        """
    }

    private func extractNumber(from asymptote: String) -> Double? {
        let cleaned = asymptote
            .replacingOccurrences(of: "x", with: "")
            .replacingOccurrences(of: "y", with: "")
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Double(cleaned)
    }

    private func interceptsXJS(graphData: GraphData) -> String {
        (graphData.intercepts["x"] ?? [])
            .compactMap { Double($0) }
            .map { String($0) }
            .joined(separator: ",")
    }

    private func interceptsYJS(graphData: GraphData) -> String {
        (graphData.intercepts["y"] ?? [])
            .compactMap { Double($0) }
            .map { String($0) }
            .joined(separator: ",")
    }
}

#Preview {
    MathGraphView(graphData: GraphData(
        isFunction: true,
        expression: "1/x",
        variable: "x",
        domain: "(-\u{221E}, 0) \u{222A} (0, +\u{221E})",
        range: "(-\u{221E}, 0) \u{222A} (0, +\u{221E})",
        intercepts: ["x": [], "y": []],
        asymptotes: ["vertical": ["x = 0"], "horizontal": ["y = 0"], "oblique": []],
        criticalPoints: [CriticalPoint(x: "0", y: "undefined", type: "discontinuity")],
        behavior: ["x_to_neg_inf": "0\u{207B}", "x_to_pos_inf": "0\u{207A}"]
    ))
    .padding()
}
