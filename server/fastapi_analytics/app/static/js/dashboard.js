// ============================================
// HypeHere Analytics Dashboard - JavaScript
// ============================================

let chart = null;
let currentPeriod = 30;

// ----- Initialize -----
document.addEventListener('DOMContentLoaded', () => {
    loadInsights();
    setupEventListeners();
});

// ----- Event Listeners -----
function setupEventListeners() {
    // Search button
    document.getElementById('search-btn').addEventListener('click', handleSearch);

    // Enter key in search input
    document.getElementById('ticker-input').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            handleSearch();
        }
    });

    // Period buttons
    document.querySelectorAll('.period-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('.period-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            currentPeriod = parseInt(e.target.dataset.days);

            const ticker = document.getElementById('ticker-input').value.trim();
            if (ticker) {
                searchTicker(ticker, currentPeriod);
            }
        });
    });
}

// ----- Load Market Insights -----
async function loadInsights() {
    try {
        const response = await fetch('/api/v1/scores/insights?top=5&bottom=5');
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        // Update date display
        if (data.date) {
            document.getElementById('data-date').textContent = `${data.date} 기준`;
        }

        renderTopMovers(data.top_movers);
        renderBottomMovers(data.bottom_movers);
    } catch (error) {
        console.error('Failed to load insights:', error);
        document.getElementById('top-movers').innerHTML = '<div class="loading">데이터를 불러올 수 없습니다.</div>';
        document.getElementById('bottom-movers').innerHTML = '<div class="loading">데이터를 불러올 수 없습니다.</div>';
    }
}

// ----- Render Top Movers -----
function renderTopMovers(movers) {
    const container = document.getElementById('top-movers');
    if (!movers || movers.length === 0) {
        container.innerHTML = '<div class="loading">데이터가 없습니다.</div>';
        return;
    }

    container.innerHTML = movers.map(m => `
        <div class="ticker-card top-mover" onclick="handleCardClick('${m.ticker}')">
            <div class="card-header">
                <span class="ticker">${m.ticker}</span>
                <span class="name">${m.name || '정보 없음'}</span>
            </div>
            <div class="card-stats">
                <span class="score-label">점수:</span>
                <span class="score">${m.score.toFixed(1)}</span>
                <span class="signal ${m.signal || 'HOLD'}">${m.signal || 'HOLD'}</span>
            </div>
        </div>
    `).join('');
}

// ----- Render Bottom Movers -----
function renderBottomMovers(movers) {
    const container = document.getElementById('bottom-movers');
    if (!movers || movers.length === 0) {
        container.innerHTML = '<div class="loading">데이터가 없습니다.</div>';
        return;
    }

    container.innerHTML = movers.map(m => `
        <div class="ticker-card bottom-mover" onclick="handleCardClick('${m.ticker}')">
            <div class="card-header">
                <span class="ticker">${m.ticker}</span>
                <span class="name">${m.name || '정보 없음'}</span>
            </div>
            <div class="card-stats">
                <span class="score-label">점수:</span>
                <span class="score">${m.score.toFixed(1)}</span>
                <span class="signal ${m.signal || 'HOLD'}">${m.signal || 'HOLD'}</span>
            </div>
        </div>
    `).join('');
}

// ----- Handle Card Click -----
function handleCardClick(ticker) {
    document.getElementById('ticker-input').value = ticker;
    searchTicker(ticker, currentPeriod);

    // Scroll to chart
    document.getElementById('chart-section').scrollIntoView({ behavior: 'smooth' });
}

// ----- Handle Search -----
function handleSearch() {
    const ticker = document.getElementById('ticker-input').value.trim();
    if (!ticker) {
        alert('티커를 입력해주세요.');
        return;
    }
    searchTicker(ticker, currentPeriod);
}

// ----- Search Ticker -----
async function searchTicker(ticker, days) {
    try {
        // Calculate date range
        const toDate = new Date();
        const fromDate = new Date();
        fromDate.setDate(fromDate.getDate() - days);

        const fromStr = fromDate.toISOString().split('T')[0];
        const toStr = toDate.toISOString().split('T')[0];

        const response = await fetch(`/api/v1/scores/${ticker.toUpperCase()}?from=${fromStr}&to=${toStr}`);
        if (!response.ok) {
            if (response.status === 404) {
                alert(`'${ticker}' 종목의 데이터를 찾을 수 없습니다.`);
            } else {
                throw new Error(`HTTP ${response.status}`);
            }
            return;
        }

        const data = await response.json();
        renderChart(data.ticker, data.scores);
        renderTable(data.scores);

        // Show sections
        document.getElementById('chart-section').style.display = 'block';
        document.getElementById('table-section').style.display = 'block';
    } catch (error) {
        console.error('Failed to search ticker:', error);
        alert('데이터를 불러오는 중 오류가 발생했습니다.');
    }
}

// ----- Render Chart -----
function renderChart(ticker, scores) {
    if (!scores || scores.length === 0) {
        return;
    }

    // Update chart title
    document.getElementById('chart-title').textContent = `📈 ${ticker} - 점수 변화`;

    // 1. 날짜를 Date 객체로 변환하여 {x, y} 형식으로 준비
    const dataPoints = scores.map(s => ({
        x: new Date(s.date),
        y: s.score
    }));

    // 2. 과거 데이터 기간 계산
    const firstDate = new Date(scores[0].date);
    const lastDate = new Date(scores[scores.length - 1].date);
    const pastDays = Math.ceil((lastDate - firstDate) / (1000 * 60 * 60 * 24));

    // 3. 미래 확장 길이 계산 (40% 영역 확보)
    const futureDays = Math.round(pastDays * (40 / 60));

    // 4. 최대 날짜 설정 (미래 포함)
    const maxDate = new Date(lastDate);
    maxDate.setDate(maxDate.getDate() + futureDays);

    // 비율 검증 (개발용 - 콘솔에 출력)
    const totalDays = pastDays + futureDays;
    const ratio = (pastDays / totalDays * 100).toFixed(1);
    console.log(`📊 Chart Viewport: Past=${pastDays}d, Future=${futureDays}d, Total=${totalDays}d, Ratio=${ratio}% (목표: 60.0%)`);

    // Destroy previous chart
    if (chart) {
        chart.destroy();
    }

    // Create new chart
    const ctx = document.getElementById('score-chart').getContext('2d');
    chart = new Chart(ctx, {
        type: 'line',
        data: {
            datasets: [{
                label: '점수',
                data: dataPoints,  // ✅ {x, y} 객체 배열
                borderColor: '#4f46e5',
                backgroundColor: 'rgba(79, 70, 229, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.3,
                pointRadius: 4,
                pointHoverRadius: 6,
                pointBackgroundColor: '#4f46e5',
                pointBorderColor: '#fff',
                pointBorderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    padding: 12,
                    titleFont: {
                        size: 14
                    },
                    bodyFont: {
                        size: 13
                    },
                    callbacks: {
                        title: function(context) {
                            const date = new Date(context[0].parsed.x);
                            return date.toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric' });
                        },
                        label: function(context) {
                            return '점수: ' + context.parsed.y.toFixed(1);
                        }
                    }
                },
                // ✅ 현재 날짜 수직선 추가
                annotation: {
                    annotations: {
                        todayLine: {
                            type: 'line',
                            xMin: new Date(),
                            xMax: new Date(),
                            borderColor: 'rgba(255, 99, 132, 0.7)',
                            borderWidth: 2,
                            borderDash: [5, 5],
                            label: {
                                display: true,
                                content: '오늘',
                                position: 'start',
                                backgroundColor: 'rgba(255, 99, 132, 0.7)',
                                color: '#fff',
                                padding: 4,
                                font: {
                                    size: 11
                                }
                            }
                        }
                    }
                }
            },
            scales: {
                x: {
                    type: 'time',  // ✅ time scale로 변경
                    min: firstDate,  // ✅ 시작일 명시
                    max: maxDate,    // ✅ 종료일 (미래 포함)

                    time: {
                        unit: 'day',
                        displayFormats: {
                            day: 'MM/dd'  // 월/일 형식
                        },
                        tooltipFormat: 'yyyy-MM-dd'
                    },

                    grid: {
                        display: true,
                        color: 'rgba(0, 0, 0, 0.05)',
                        drawOnChartArea: true
                    },

                    ticks: {
                        maxRotation: 45,
                        minRotation: 45,
                        autoSkip: true,
                        maxTicksLimit: 10,  // 최대 10개 라벨

                        // 미래 날짜는 연한 색으로 표시
                        color: function(context) {
                            const tickDate = new Date(context.tick.value);
                            return tickDate > lastDate ? '#999999' : '#666666';
                        }
                    },

                    border: {
                        display: true,
                        color: '#ddd'
                    }
                },
                y: {
                    beginAtZero: false,
                    grid: {
                        color: 'rgba(0, 0, 0, 0.05)'
                    },
                    ticks: {
                        callback: function(value) {
                            return value.toFixed(1);
                        }
                    }
                }
            },
            interaction: {
                mode: 'nearest',
                axis: 'x',
                intersect: false
            }
        }
    });
}

// ----- Render Table -----
function renderTable(scores) {
    if (!scores || scores.length === 0) {
        return;
    }

    const tbody = document.querySelector('#score-table tbody');
    // Reverse sorting: latest date first
    const sortedScores = [...scores].reverse();
    tbody.innerHTML = sortedScores.map(s => `
        <tr>
            <td>${s.date}</td>
            <td><strong>${s.score.toFixed(1)}</strong></td>
            <td><span class="signal ${s.signal || 'HOLD'}">${s.signal || 'HOLD'}</span></td>
        </tr>
    `).join('');
}
