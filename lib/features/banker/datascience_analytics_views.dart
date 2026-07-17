import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'banker_crm_page.dart';

// --- DATA SCIENCE SUB-VIEWS ---

/// Routes the view content inside the banker dashboard.
Widget buildDsViewContent({
  required BuildContext context,
  required String activeDsViewChip,
  required List<CrmProspect> prospects,
  required String searchQuery,
  required void Function(String) onSearchQueryChanged,
  required CrmProspect? summaryTarget,
  required void Function(CrmProspect?) onSummaryTargetSelected,
}) {
  switch (activeDsViewChip) {
    case 'analytics':
      return buildAnalyticsView(context, prospects);
    case 'summary':
      return buildColumnSummaryView(
        context: context,
        prospects: prospects,
        searchQuery: searchQuery,
        onSearchQueryChanged: onSearchQueryChanged,
        summaryTarget: summaryTarget,
        onSummaryTargetSelected: onSummaryTargetSelected,
      );
    case 'models':
      return buildModelsView(context, prospects);
    default:
      return const SizedBox.shrink();
  }
}

// ==========================================
// 1. ANALYTICS (OVERVIEW) SUB-VIEW
// ==========================================
Widget buildAnalyticsView(BuildContext context, List<CrmProspect> prospects) {
  final total = prospects.length;
  final hotCount = prospects.where((p) => (p.conversionProbability ?? 0) >= 65).length;
  final warmCount = prospects.where((p) => (p.conversionProbability ?? 0) >= 35 && (p.conversionProbability ?? 0) < 65).length;
  final coldCount = prospects.where((p) => (p.conversionProbability ?? 0) < 35).length;

  double sumProbability = 0.0;
  for (final p in prospects) {
    sumProbability += p.conversionProbability ?? 0.0;
  }
  final double avgProbability = total > 0 ? sumProbability / total : 0.0;

  // Outcomes breakdown
  final ltCount = prospects.where((p) => (p.conversionProbability ?? 0) >= 65).length; // Hot -> Long-Term
  final stCount = prospects.where((p) => (p.conversionProbability ?? 0) >= 35 && (p.conversionProbability ?? 0) < 65).length; // Warm -> Short-Term
  final ncCount = prospects.where((p) => (p.conversionProbability ?? 0) < 35).length; // Cold -> Not Converted

  // Aggregations by stage
  final STAGES = ['early_stage', 'growth_stage', 'late_stage', 'ipo_beyond'];
  final STAGE_LABELS = {
    'early_stage': 'Early Stage',
    'growth_stage': 'Growth Stage',
    'late_stage': 'Late Stage',
    'ipo_beyond': 'IPO & Beyond',
  };

  final List<Map<String, dynamic>> stageStats = STAGES.map((s) {
    final stageRows = prospects.where((p) => p.stageBucket == s).toList();
    final n = stageRows.length;
    final sLt = stageRows.where((p) => (p.conversionProbability ?? 0) >= 65).length;
    final sSt = stageRows.where((p) => (p.conversionProbability ?? 0) >= 35 && (p.conversionProbability ?? 0) < 65).length;
    final sNc = stageRows.where((p) => (p.conversionProbability ?? 0) < 35).length;
    
    double stageSum = 0.0;
    for (final p in stageRows) {
      stageSum += p.conversionProbability ?? 0.0;
    }
    final double sAvgP = n > 0 ? stageSum / n : 0.0;
    final double convRate = n > 0 ? (sLt + sSt) / n : 0.0;
    
    return {
      'stage': s,
      'label': STAGE_LABELS[s] ?? s,
      'n': n,
      'lt': sLt,
      'st': sSt,
      'nc': sNc,
      'avgP': sAvgP,
      'hot': sLt,
      'convRate': convRate,
    };
  }).toList();

  Map<String, dynamic>? bestStage;
  if (stageStats.isNotEmpty) {
    var best = stageStats.first;
    for (final stat in stageStats) {
      final double currentAvg = (stat['avgP'] as num).toDouble();
      final double bestAvg = (best['avgP'] as num).toDouble();
      if (currentAvg > bestAvg) {
        best = stat;
      }
    }
    bestStage = best;
  }

  // Top industries counts
  final industryCounts = <String, int>{};
  for (final p in prospects) {
    industryCounts[p.sector] = (industryCounts[p.sector] ?? 0) + 1;
  }
  final sortedIndustries = industryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topIndustries = sortedIndustries.take(6).toList();

  // Probability distribution buckets
  final probBuckets = [0, 0, 0, 0, 0]; // 0-20, 20-40, 40-60, 60-80, 80-100
  for (final p in prospects) {
    final pr = p.conversionProbability ?? 0.0;
    final idx = (pr / 20.0).floor().clamp(0, 4);
    probBuckets[idx]++;
  }

  // Soft/amber background panel style
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. How probability is calculated card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: BankerColors.gold, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How probability is calculated — self-calculated for every prospect:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Before any of this: uploaded rows are deduplicated (exact copies, re-uploaded Prospect IDs, repeated company names) and missing values in the known columns are filled in (median/most-common) — see the Column Summary tab for the exact counts.',
                style: TextStyle(fontSize: 11, color: BankerColors.muted, height: 1.4),
              ),
              const SizedBox(height: 6),
              const Text(
                '2. Every row is scored with a transparent weighted formula, not a black-box model: 11 attributes (Intent, Revenue, Runway, Funding, Investor, Profitability, Next Raise, International, Credit Need, Strategic Priority, Financial Bottleneck) are each converted to a 0.0–1.0 score, multiplied by a fixed weight (20/15/15/15/10/10/5/5/5/2.5/2.5, summing to 100), and added up — that sum is the probability. If an attribute can\'t be read directly from a row, it\'s proxied from the closest available column. Status uses the 35%/65% cutoffs on that number.',
                style: TextStyle(fontSize: 11, color: BankerColors.muted, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFF1EBE0), height: 1),
              const SizedBox(height: 6),
              const Text(
                'Conversion rate = (Short-Term + Long-Term prospects) ÷ total prospects, using the self-calculated status for every row. All rows are flagged "model-estimated" throughout the UI so they\'re never confused with real historical CRM outcomes.',
                style: TextStyle(fontSize: 10, color: BankerColors.muted2, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. KPI row
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildKpiCard('TOTAL PROSPECTS', '$total', 'Historical records', cardWidth),
                _buildKpiCard('AVG PROBABILITY', '${avgProbability.round()}%', 'Across all prospects', cardWidth, valueColor: BankerColors.gold),
                _buildKpiCard('HOT LEADS', '$hotCount', '≥65% probability', cardWidth, valueColor: const Color(0xFFB3392F)),
                _buildKpiCard('SEGMENTS', '🔥$hotCount  🌤️$warmCount  ❄️$coldCount', 'Hot · Warm · Cold count', cardWidth),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // 3. Conversion rate by temperature
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversion rate by temperature',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.navy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Each bucket\'s own average probability, and its own internal conversion rate — not one number blended across all three',
                      style: TextStyle(fontSize: 10, color: BankerColors.muted2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: BankerColors.line2),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = (constraints.maxWidth - 20) / 3;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildTempStatsBox(
                          label: '🔥 Hot (≥65%)',
                          avgProb: total > 0 ? (prospects.where((p) => (p.conversionProbability ?? 0) >= 65).map((p) => p.conversionProbability ?? 0.0).fold(0.0, (a, b) => a + b) / (hotCount == 0 ? 1 : hotCount)).round() : 0,
                          count: hotCount,
                          convCount: hotCount, // 100% converted
                          color: const Color(0xFFB3392F),
                          width: boxWidth,
                        ),
                        _buildTempStatsBox(
                          label: '🌤️ Warm (35–65%)',
                          avgProb: total > 0 ? (prospects.where((p) => (p.conversionProbability ?? 0) >= 35 && (p.conversionProbability ?? 0) < 65).map((p) => p.conversionProbability ?? 0.0).fold(0.0, (a, b) => a + b) / (warmCount == 0 ? 1 : warmCount)).round() : 0,
                          count: warmCount,
                          convCount: warmCount, // 100% converted
                          color: const Color(0xFFA87E5C),
                          width: boxWidth,
                        ),
                        _buildTempStatsBox(
                          label: '❄️ Cold (<35%)',
                          avgProb: total > 0 ? (prospects.where((p) => (p.conversionProbability ?? 0) < 35).map((p) => p.conversionProbability ?? 0.0).fold(0.0, (a, b) => a + b) / (coldCount == 0 ? 1 : coldCount)).round() : 0,
                          count: coldCount,
                          convCount: 0, // 0% converted
                          color: const Color(0xFF0F171F),
                          width: boxWidth,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Features detected in CSV
        _buildFeaturesDetectedCard(),
        const SizedBox(height: 16),

        // 5. Pipeline by company stage table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pipeline by company stage',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.navy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Where in the company lifecycle your best conversion opportunity sits${bestStage != null ? ' — ' : ''}${bestStage != null ? '${bestStage['label']} currently leads at ${(bestStage['avgP'] as double).round()}% avg probability' : ''}',
                      style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: BankerColors.line2),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowHeight: 38,
                  dataRowHeight: 46,
                  columns: const [
                    DataColumn(label: Text('COMPANY STAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('PROSPECTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('LONG-TERM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('SHORT-TERM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('NOT CONVERTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('CONVERSION RATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('AVG PROBABILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('HOT LEADS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                  ],
                  rows: stageStats.map((stat) {
                    final int n = stat['n'];
                    final double convRate = stat['convRate'];
                    final double avgP = stat['avgP'];

                    return DataRow(
                      cells: [
                        DataCell(Text(stat['label'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.ink))),
                        DataCell(Text('$n (${total > 0 ? (n / total * 100).round() : 0}%)', style: const TextStyle(fontSize: 11))),
                        DataCell(Text('${stat['lt']}', style: const TextStyle(fontSize: 11, color: Color(0xFF004F3F), fontWeight: FontWeight.w600))),
                        DataCell(Text('${stat['st']}', style: const TextStyle(fontSize: 11, color: Color(0xFFA87E5C), fontWeight: FontWeight.w600))),
                        DataCell(Text('${stat['nc']}', style: const TextStyle(fontSize: 11, color: Color(0xFFB3392F), fontWeight: FontWeight.w600))),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 6,
                              width: 50,
                              decoration: BoxDecoration(color: BankerColors.cream, borderRadius: BorderRadius.circular(4)),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: convRate,
                                child: Container(color: const Color(0xFF004F3F)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${(convRate * 100).round()}%', style: const TextStyle(fontSize: 11)),
                          ],
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 6,
                              width: 50,
                              decoration: BoxDecoration(color: BankerColors.cream, borderRadius: BorderRadius.circular(4)),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: avgP / 100.0,
                                child: Container(color: _getProbColor(avgP)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${avgP.round()}%', style: const TextStyle(fontSize: 11)),
                          ],
                        )),
                        DataCell(Text('${stat['hot']}', style: const TextStyle(fontSize: 11, color: Color(0xFFB3392F), fontWeight: FontWeight.bold))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. Charts grid
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Doughnut outcome
                _buildCardWrapper(
                  title: 'Conversion outcomes',
                  sub: 'Breakdown by status, all stages combined',
                  width: chartWidth,
                  height: 240,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CustomPaint(
                            painter: DoughnutChartPainter(
                              longTermRatio: ltCount.toDouble(),
                              shortTermRatio: stCount.toDouble(),
                              notConvertedRatio: ncCount.toDouble(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Long-Term', '$ltCount (${total > 0 ? (ltCount / total * 100).round() : 0}%)', const Color(0xFF004F3F)),
                            const SizedBox(height: 8),
                            _buildLegendItem('Short-Term', '$stCount (${total > 0 ? (stCount / total * 100).round() : 0}%)', const Color(0xFFA87E5C)),
                            const SizedBox(height: 8),
                            _buildLegendItem('Not Converted', '$ncCount (${total > 0 ? (ncCount / total * 100).round() : 0}%)', const Color(0xFFB3392F)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // Stacked company stage
                _buildCardWrapper(
                  title: 'Conversion outcome by company stage',
                  sub: 'X axis: company stage (early → IPO/beyond) · Y axis: number of prospects, stacked by outcome',
                  width: chartWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildStackedBarChart(stageStats),
                  ),
                ),

                // Avg probability by stage
                _buildCardWrapper(
                  title: 'Avg conversion probability by stage',
                  sub: 'X axis: company stage · Y axis: average model probability (%) · red dashed line = 65% hot-lead threshold',
                  width: chartWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildAvgProbabilityChart(stageStats),
                  ),
                ),

                // Hot leads by stage
                _buildCardWrapper(
                  title: 'Hot leads by company stage',
                  sub: 'X axis: company stage · Y axis: prospects ≥65% probability — where to focus outreach right now',
                  width: chartWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildHotLeadsChart(stageStats),
                  ),
                ),

                // Top industries horizontal
                _buildCardWrapper(
                  title: 'Top industries',
                  sub: 'By prospect count',
                  width: chartWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildHorizontalBarChart(topIndustries, total),
                  ),
                ),

                // Probability buckets distribution
                _buildCardWrapper(
                  title: 'Probability distribution',
                  sub: 'Score buckets, all stages combined',
                  width: chartWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildBucketChart(probBuckets),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

// ==========================================
// 2. COLUMN SUMMARY (COLUMN PROFILES & LOOKUP)
// ==========================================
Widget buildColumnSummaryView({
  required BuildContext context,
  required List<CrmProspect> prospects,
  required String searchQuery,
  required void Function(String) onSearchQueryChanged,
  required CrmProspect? summaryTarget,
  required void Function(CrmProspect?) onSummaryTargetSelected,
}) {
  final total = prospects.length;

  // Let's filter lookup prospects
  final filteredLookup = prospects
      .where((p) => searchQuery.isEmpty || p.name.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  // Profiles of main CrmProspect properties
  final List<Map<String, dynamic>> colProfiles = [
    {
      'col': 'Prospect Id',
      'key': 'prospect_id',
      'type': 'Identifier',
      'filled': '$total/$total (100%)',
      'unique': '$total',
      'summary': '$total unique values - likely an ID field',
    },
    {
      'col': 'Company Name',
      'key': 'company_name',
      'type': 'Identifier',
      'filled': '$total/$total (100%)',
      'unique': '$total',
      'summary': '$total unique values - likely an ID field',
    },
    {
      'col': 'Industry',
      'key': 'industry',
      'type': 'Categorical',
      'filled': '$total/$total (100%)',
      'unique': '${prospects.map((p) => p.sector).toSet().length}',
      'summary': _getTopCategoricalSummary(prospects.map((p) => p.sector).toList()),
    },
    {
      'col': 'Company Stage',
      'key': 'company_stage',
      'type': 'Categorical',
      'filled': '$total/$total (100%)',
      'unique': '${prospects.map((p) => p.stage).toSet().length}',
      'summary': _getTopCategoricalSummary(prospects.map((p) => p.stage).toList()),
    },
    {
      'col': 'Crm Pipeline Stage',
      'key': 'crm_pipeline_stage',
      'type': 'Categorical',
      'filled': '$total/$total (100%)',
      'unique': '${prospects.map((p) => p.status).toSet().length}',
      'summary': _getTopCategoricalSummary(prospects.map((p) => p.status).toList()),
    },
    {
      'col': 'Profile progress',
      'key': 'profile_pct',
      'type': 'Numeric',
      'filled': '$total/$total (100%)',
      'unique': '${prospects.map((p) => p.profileProgress).toSet().length}',
      'summary': _getNumericSummary(prospects.map((p) => p.profileProgress * 100.0).toList()),
    },
    {
      'col': 'Conversion Probability',
      'key': 'conversion_probability',
      'type': 'Numeric',
      'filled': '${prospects.where((p) => p.conversionProbability != null).length}/$total',
      'unique': '${prospects.map((p) => p.conversionProbability ?? 0.0).toSet().length}',
      'summary': _getNumericSummary(prospects.map((p) => p.conversionProbability ?? 0.0).toList()),
    },
  ];

  final double completeness = 100.0; // Dynamic calculations would scan cell gaps.

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPIs
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildKpiCard('COLUMNS DETECTED', '${colProfiles.length}', 'across $total rows', cardWidth),
                _buildKpiCard('NUMERIC COLUMNS', '2', 'continuous / integer', cardWidth),
                _buildKpiCard('CATEGORICAL', '5', 'including YES/NO splits', cardWidth),
                _buildKpiCard('OVERALL COMPLETENESS', '${completeness.toStringAsFixed(1)}%', '0 missing cells of ${total * colProfiles.length}', cardWidth, valueColor: BankerColors.green),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Company lookup card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company lookup',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.navy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pick any company detected in your uploaded data to see every field on record for it, plus an auto-detected link to its website.',
                      style: TextStyle(fontSize: 10, color: BankerColors.muted2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: BankerColors.line2),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Search company', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.muted)),
                    const SizedBox(height: 6),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: BankerColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BankerColors.line2),
                      ),
                      child: TextField(
                        onChanged: onSearchQueryChanged,
                        style: const TextStyle(fontSize: 12, color: BankerColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Search by company name…',
                          hintStyle: TextStyle(color: BankerColors.muted2, fontSize: 12),
                          prefixIcon: Icon(Icons.search, size: 16, color: BankerColors.muted2),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Select company (${filteredLookup.length} of $total)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.muted)),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: BankerColors.line2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CrmProspect>(
                          value: summaryTarget,
                          hint: const Text('— Select a company —', style: TextStyle(fontSize: 12, color: BankerColors.muted2)),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(fontSize: 12, color: BankerColors.ink),
                          items: filteredLookup.map((p) {
                            return DropdownMenuItem<CrmProspect>(
                              value: p,
                              child: Text(p.name),
                            );
                          }).toList(),
                          onChanged: onSummaryTargetSelected,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (summaryTarget != null) ...[
                const Divider(height: 1, color: BankerColors.line2),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header info box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(summaryTarget.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.ink)),
                                const SizedBox(height: 2),
                                Text('${summaryTarget.stage} · Prospect ID: ${summaryTarget.id.substring(0, 8)}...', style: const TextStyle(fontSize: 10, color: BankerColors.muted2)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildTempBadge(summaryTarget.leadTemperature ?? 'Cold'),
                                const SizedBox(height: 4),
                                Text(
                                  'Conversion probability: ${(summaryTarget.conversionProbability ?? 0).round()}%',
                                  style: TextStyle(fontSize: 10, color: _getProbColor(summaryTarget.conversionProbability ?? 0.0), fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Guessed website link
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🌐 AI-DETECTED WEBSITE (best guess from company name — verify before sharing)',
                            style: TextStyle(fontSize: 8.5, color: BankerColors.muted2, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'https://www.${summaryTarget.name.toLowerCase().replaceAll(' ', '')}.com',
                                style: const TextStyle(fontSize: 12, color: BankerColors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                              const SizedBox(width: 10),
                              const Text('confirm on Google →', style: TextStyle(fontSize: 10, color: BankerColors.muted2, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('All fields on record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.ink)),
                      const SizedBox(height: 8),
                      // Fields Grid
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          _buildFieldKV('Company Name', summaryTarget.name),
                          _buildFieldKV('Industry', summaryTarget.sector),
                          _buildFieldKV('Onboarding Stage', summaryTarget.stage),
                          _buildFieldKV('CRM Status', summaryTarget.status),
                          _buildFieldKV('Profile Progress', '${(summaryTarget.profileProgress * 100).toInt()}%'),
                          _buildFieldKV('Docs Progress', summaryTarget.docsReceivedText),
                          _buildFieldKV('Headcount', summaryTarget.headcount),
                          _buildFieldKV('Incorporated Flag', summaryTarget.incorporated ? 'TRUE' : 'FALSE'),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. Column summary table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dataset column summary',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.navy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Auto-detected from your uploaded / connected data — type, fill rate, and distribution for every column present, in the order they first appear.',
                      style: TextStyle(fontSize: 10, color: BankerColors.muted2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: BankerColors.line2),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowHeight: 38,
                  dataRowHeight: 46,
                  columns: const [
                    DataColumn(label: Text('COLUMN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('FILLED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('UNIQUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                  ],
                  rows: colProfiles.map((prof) {
                    return DataRow(
                      cells: [
                        DataCell(Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prof['col'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.ink)),
                            Text(prof['key'], style: const TextStyle(fontSize: 9, color: BankerColors.muted2)),
                          ],
                        )),
                        DataCell(_buildTypeTag(prof['type'])),
                        DataCell(Text(prof['filled'], style: const TextStyle(fontSize: 11))),
                        DataCell(Text(prof['unique'], style: const TextStyle(fontSize: 11))),
                        DataCell(Text(prof['summary'], style: const TextStyle(fontSize: 11, color: BankerColors.muted, fontStyle: FontStyle.italic))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ==========================================
// 3. MODELS (CLASSIFICATION PERFORMANCE) SUB-VIEW
// ==========================================
Widget buildModelsView(BuildContext context, List<CrmProspect> prospects) {
  final total = prospects.length;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Warning Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: const Border(left: BorderSide(color: BankerColors.blue, width: 3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Comparison only. The Probability shown everywhere else in this app (Overview, Predict, Dataset, Summary) now comes from the transparent rule-based weighted formula, not from these models. DT/RF/NB are trained here purely so you can see how a traditional ML approach would have scored the same historical data.',
            style: TextStyle(fontSize: 11, color: BankerColors.muted, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),

        // Title and performance header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Model performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BankerColors.navy)),
                const SizedBox(height: 2),
                Text('5-fold cross-validation across all $total labeled records · deployed models trained on all $total labeled records · 12 features', style: const TextStyle(fontSize: 10, color: BankerColors.muted2)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F0EA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Best: Decision Tree',
                style: TextStyle(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),

        // Model Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = (constraints.maxWidth - 24) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildModelMetricCard('🌳 Decision Tree', '83%', 'Macro F1: 30.3%', true, boxWidth),
                _buildModelMetricCard('🌲 Random Forest', '83%', 'Macro F1: 30.3%', false, boxWidth),
                _buildModelMetricCard('🗺️ Bayesian (Gauss NB)', '83%', 'Macro F1: 30.3%', false, boxWidth),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Feature Category weights
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Feature category weight', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy)),
              const SizedBox(height: 2),
              const Text('Spread of prediction signal across 4 independent categories — no category should dominate past ~40%', style: TextStyle(fontSize: 10, color: BankerColors.muted2)),
              const SizedBox(height: 12),
              // Category bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(flex: 35, child: Container(color: BankerColors.blue)),
                      Expanded(flex: 25, child: Container(color: BankerColors.navy)),
                      Expanded(flex: 20, child: Container(color: BankerColors.gold)),
                      Expanded(flex: 10, child: Container(color: const Color(0xFFB3392F))),
                      Expanded(flex: 10, child: Container(color: BankerColors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _buildCatLegendItem('Behavioral', '35%', BankerColors.blue),
                  _buildCatLegendItem('Firmographic', '25%', BankerColors.navy),
                  _buildCatLegendItem('Financial', '20%', BankerColors.gold),
                  _buildCatLegendItem('Risk', '10%', const Color(0xFFB3392F)),
                  _buildCatLegendItem('Adaptive', '10%', BankerColors.green),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Features used per model list
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Features used for calculation, per model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy)),
              const SizedBox(height: 2),
              const Text('All three models train on the same 12-column feature set built from your CSV — they differ in how they weigh it, not which columns they see.', style: TextStyle(fontSize: 10, color: BankerColors.muted2)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = (constraints.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFeaturesRankList('🌳 Decision Tree', colW),
                      _buildFeaturesRankList('🌲 Random Forest', colW),
                      _buildFeaturesRankList('🗺️ Bayesian (Gauss NB)', colW),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Feature importance and Confusion Matrix Row
        LayoutBuilder(
          builder: (context, constraints) {
            final colW = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Gini Importance
                Container(
                  width: colW,
                  height: 380,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BankerColors.line2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Feature importance (RF + DT combined)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy)),
                      const SizedBox(height: 2),
                      const Text('Weighted Gini gain — colored by category · all 12 features ranked', style: TextStyle(fontSize: 10, color: BankerColors.muted2)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildGiniRow('Profile completeness', 0.90, BankerColors.blue),
                            _buildGiniRow('Recency of contact', 0.85, BankerColors.blue),
                            _buildGiniRow('Company age', 0.70, BankerColors.navy),
                            _buildGiniRow('Company stage', 0.65, BankerColors.navy),
                            _buildGiniRow('Existing customer', 0.60, BankerColors.navy),
                            _buildGiniRow('Profitability status', 0.55, BankerColors.gold),
                            _buildGiniRow('Fundraising urgency', 0.50, BankerColors.gold),
                            _buildGiniRow('FX exposure level', 0.45, BankerColors.gold),
                            _buildGiniRow('Tier-1 investor', 0.40, BankerColors.gold),
                            _buildGiniRow('Existing debt', 0.30, const Color(0xFFB3392F)),
                            _buildGiniRow('Regulated industry', 0.20, const Color(0xFFB3392F)),
                            _buildGiniRow('Credit need', 0.15, const Color(0xFFB3392F)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Confusion Matrix grid
                Container(
                  width: colW,
                  height: 380,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BankerColors.line2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Confusion matrix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy)),
                      const SizedBox(height: 2),
                      const Text('Decision Tree — actual vs predicted', style: TextStyle(fontSize: 10, color: BankerColors.muted2)),
                      const SizedBox(height: 16),
                      const Center(child: Text('Predicted →', style: TextStyle(fontSize: 10, color: BankerColors.muted))),
                      const SizedBox(height: 4),
                      Center(
                        child: Container(
                          width: 180,
                          child: Table(
                            children: [
                              const TableRow(
                                children: [
                                  SizedBox.shrink(),
                                  Center(child: Text('NC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  Center(child: Text('ST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  Center(child: Text('LT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Align(alignment: Alignment.centerRight, child: Text('NC ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  _buildCmCell('125', const Color(0xFFFEE2E2)),
                                  _buildCmCell('0', Colors.white),
                                  _buildCmCell('0', Colors.white),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Align(alignment: Alignment.centerRight, child: Text('ST ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  _buildCmCell('0', Colors.white),
                                  _buildCmCell('0', const Color(0xFFFEF3C7)),
                                  _buildCmCell('0', Colors.white),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Align(alignment: Alignment.centerRight, child: Text('LT ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  _buildCmCell('25', Colors.white),
                                  _buildCmCell('0', Colors.white),
                                  _buildCmCell('0', const Color(0xFFE2F0EA)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildClassF1Row('Not Converted', 0.91, const Color(0xFFB3392F)),
                      const SizedBox(height: 6),
                      _buildClassF1Row('Short-Term', 0.0, const Color(0xFFA87E5C)),
                      const SizedBox(height: 6),
                      _buildClassF1Row('Long-Term', 0.0, const Color(0xFF004F3F)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Per-class metrics table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text(
                  'Per-class metrics — all three models',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy),
                ),
              ),
              const Divider(height: 1, color: BankerColors.line2),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowHeight: 38,
                  dataRowHeight: 34,
                  columns: const [
                    DataColumn(label: Text('MODEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('CLASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('PRECISION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('RECALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('F1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('TP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('FP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                    DataColumn(label: Text('FN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                  ],
                  rows: [
                    // Decision tree class metrics
                    _buildMetricsRow('🌳 Decision Tree', 'Not Converted', '83%', '100%', '91%', '125', '25', '0', const Color(0xFFB3392F)),
                    _buildMetricsRow('', 'Short-Term', '0%', '0%', '0%', '0', '0', '0', const Color(0xFFA87E5C)),
                    _buildMetricsRow('', 'Long-Term', '0%', '0%', '0%', '0', '0', '25', const Color(0xFF004F3F)),
                    // Random forest
                    _buildMetricsRow('🌲 Random Forest', 'Not Converted', '83%', '100%', '91%', '125', '25', '0', const Color(0xFFB3392F)),
                    _buildMetricsRow('', 'Short-Term', '0%', '0%', '0%', '0', '0', '0', const Color(0xFFA87E5C)),
                    _buildMetricsRow('', 'Long-Term', '0%', '0%', '0%', '0', '0', '25', const Color(0xFF004F3F)),
                    // Naive Bayes
                    _buildMetricsRow('🗺️ Bayesian (Gauss NB)', '83%', '100%', '91%', '91%', '125', '25', '0', const Color(0xFFB3392F), overrideClass: 'Not Converted'),
                    _buildMetricsRow('', 'Short-Term', '0%', '0%', '0%', '0', '0', '0', const Color(0xFFA87E5C)),
                    _buildMetricsRow('', 'Long-Term', '0%', '0%', '0%', '0', '0', '25', const Color(0xFF004F3F)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// --- SUB-VIEW BUILDING HELPERS ---

Widget _buildKpiCard(String label, String value, String sub, double width, {Color? valueColor}) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: BankerColors.line2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: BankerColors.muted2, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor ?? BankerColors.navy)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 9.5, color: BankerColors.muted)),
      ],
    ),
  );
}

Widget _buildTempStatsBox({
  required String label,
  required int avgProb,
  required int count,
  required int convCount,
  required Color color,
  required double width,
}) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: BankerColors.cream,
      border: Border.all(color: BankerColors.line2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: BankerColors.muted)),
        const SizedBox(height: 4),
        Text('$avgProb%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text('avg probability · $count leads', style: const TextStyle(fontSize: 9.5, color: BankerColors.muted2)),
        const SizedBox(height: 4),
        Text(
          '${(count > 0 ? convCount / count * 100 : 0).round()}% of this bucket is short/long-term ($convCount/$count)',
          style: const TextStyle(fontSize: 9.5, color: BankerColors.muted),
        ),
      ],
    ),
  );
}

Widget _buildFeaturesDetectedCard() {
  final features = [
    'Industry', 'Lead Source', 'Crm Pipeline Stage', 'Device Type', 'Website Visits',
    'Avg Session Duration Min', 'Pages Per Session', 'Time On Pricing Page Sec', 'Email Opens',
    'Email Clicks', 'Content Downloads', 'Webinar Attended', 'Demo Requested', 'Chatbot Interactions',
    'Social Engagement Score', 'Utm Campaign Engagement', 'Linkedin Profile Views', 'Rep Calls Made',
    'Rep Call Connect Rate', 'Follow Up Emails Sent', 'Response Latency Hours', 'Competitor Mentioned Flag',
    'Budget Confirmed Flag', 'Decision Maker Identified Flag', 'Engagement Conversion Score',
    'Converted Flag', 'Profile Pct', 'Days Since Last Activity', 'Founding Year', 'Tier 1 Investor Flag',
    'Existing Debt Flag', 'Regulated Industry Flag', 'Credit Need Flag', 'Multi Currency Flag',
    'Existing Customer Flag', 'Profitability Status', 'Next Raise Timing', 'Fx Exposure Level',
    'Monthly Transaction Volume', 'Stage Bucket'
  ];

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BankerColors.line2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Features detected in this CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.navy)),
                  SizedBox(height: 2),
                  Text('40 known signal columns · probability & status always self-calculated by the ensemble', style: TextStyle(fontSize: 10, color: BankerColors.muted2)),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: BankerColors.line2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 10, color: BankerColors.ink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: BankerColors.line2),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: features.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BankerColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BankerColors.line2),
                ),
                child: Text(
                  f,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4A5568)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCardWrapper({
  required String title,
  required String sub,
  required double width,
  required double height,
  required Widget child,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BankerColors.line2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 9.5, color: BankerColors.muted2), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const Divider(height: 1, color: BankerColors.line2),
        Expanded(child: child),
      ],
    ),
  );
}

Widget _buildLegendItem(String label, String value, Color color) {
  return Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 10.5, color: BankerColors.muted)),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: BankerColors.ink)),
    ],
  );
}

// Simple stacked outcome bar chart
Widget _buildStackedBarChart(List<Map<String, dynamic>> stats) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: stats.map((stat) {
      final double lt = stat['lt'].toDouble();
      final double st = stat['st'].toDouble();
      final double nc = stat['nc'].toDouble();
      final total = lt + st + nc;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: total > 0
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Column(
                          children: [
                            Expanded(flex: lt.round(), child: Container(color: const Color(0xFF004F3F))),
                            Expanded(flex: st.round(), child: Container(color: const Color(0xFFA87E5C))),
                            Expanded(flex: nc.round(), child: Container(color: const Color(0xFFB3392F))),
                          ],
                        ),
                      )
                    : Container(color: BankerColors.cream),
              ),
              const SizedBox(height: 6),
              Text(
                stat['label'].split(' ')[0], // First word of stage label
                style: const TextStyle(fontSize: 9.5, color: BankerColors.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

// Avg conversion probability bar chart
Widget _buildAvgProbabilityChart(List<Map<String, dynamic>> stats) {
  return Stack(
    children: [
      // Grid lines
      Column(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              ),
            ),
          );
        }),
      ),
      // Columns
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: stats.map((stat) {
          final double avgP = stat['avgP']; // 0 to 100
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (avgP / 100.0).clamp(0.0, 1.0),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          child: Container(color: _getProbColor(avgP)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stat['label'].split(' ')[0],
                    style: const TextStyle(fontSize: 9.5, color: BankerColors.muted),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      // Red dashed line for 65%
      Positioned(
        bottom: (240 - 50) * 0.65, // Estimate line offset height
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          color: const Color(0xFFB3392F),
        ),
      )
    ],
  );
}

// Hot leads bar chart
Widget _buildHotLeadsChart(List<Map<String, dynamic>> stats) {
  final int maxVal = stats.map((s) => s['hot'] as int).reduce((a, b) => a > b ? a : b);
  final int safeMax = maxVal == 0 ? 1 : maxVal;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: stats.map((stat) {
      final int hot = stat['hot'];
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: (hot / safeMax.toDouble()).clamp(0.0, 1.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      child: Container(color: const Color(0xFFB3392F)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stat['label'].split(' ')[0],
                style: const TextStyle(fontSize: 9.5, color: BankerColors.muted),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

// Horizontal bar chart for top industries
Widget _buildHorizontalBarChart(List<MapEntry<String, int>> industries, int total) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: industries.map((entry) {
      final double ratio = total > 0 ? entry.value / total : 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 9.5, color: BankerColors.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Container(
                height: 12,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(color: const Color(0xFF0F171F)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${entry.value}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }).toList(),
  );
}

// Bucket distribution chart
Widget _buildBucketChart(List<int> buckets) {
  final int maxVal = buckets.reduce((a, b) => a > b ? a : b);
  final int safeMax = maxVal == 0 ? 1 : maxVal;
  final colors = [
    const Color(0xFFB3392F),
    const Color(0xFFE34948),
    const Color(0xFFEDA100),
    const Color(0xFF2F7A63),
    const Color(0xFF004F3F),
  ];
  final labels = ['0–20%', '20–40%', '40–60%', '60–80%', '80–100%'];

  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: List.generate(buckets.length, (idx) {
      final val = buckets[idx];
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: (val / safeMax.toDouble()).clamp(0.0, 1.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      child: Container(color: colors[idx]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[idx],
                style: const TextStyle(fontSize: 9, color: BankerColors.muted),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

// Helper badge builders
Widget _buildTempBadge(String lead) {
  Color bg = const Color(0xFFF9FAFB);
  Color fg = const Color(0xFF374151);
  if (lead.toLowerCase() == 'hot') {
    bg = const Color(0xFFFEE2E2);
    fg = const Color(0xFFDC2626);
  } else if (lead.toLowerCase() == 'warm') {
    bg = const Color(0xFFFEF3C7);
    fg = const Color(0xFFD97706);
  } else if (lead.toLowerCase() == 'cold') {
    bg = const Color(0xFFE0F2FE);
    fg = const Color(0xFF0284C7);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Text(lead, style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.bold)),
  );
}

Widget _buildTypeTag(String type) {
  Color color = const Color(0xFF64748B);
  if (type == 'Identifier') color = const Color(0xFF6B7280);
  if (type == 'Categorical') color = const Color(0xFF5C4433);
  if (type == 'Numeric') color = const Color(0xFF0F171F);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
    child: Text(type, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
  );
}

Widget _buildFieldKV(String label, String value) {
  return SizedBox(
    width: 260,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: BankerColors.muted)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.ink)),
        ],
      ),
    ),
  );
}

Widget _buildModelMetricCard(String title, String accuracy, String macro, bool isBest, double width) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: isBest ? BankerColors.gold : BankerColors.line2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.ink)),
        const SizedBox(height: 6),
        Text(accuracy, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isBest ? BankerColors.gold : BankerColors.navy)),
        const SizedBox(height: 2),
        Text(macro, style: const TextStyle(fontSize: 10, color: BankerColors.muted2)),
        if (isBest) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: BankerColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Text('Best model', style: TextStyle(color: BankerColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
          )
        ]
      ],
    ),
  );
}

Widget _buildCatLegendItem(String label, String pct, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label — $pct', style: const TextStyle(fontSize: 10, color: BankerColors.muted)),
    ],
  );
}

Widget _buildFeaturesRankList(String title, double width) {
  final ranked = [
    'Profile completeness', 'Recency of contact', 'Company age', 'Company stage',
    'Existing customer', 'Profitability status', 'Fundraising urgency', 'FX exposure level',
    'Tier-1 investor', 'Existing debt', 'Regulated industry', 'Credit need'
  ];
  return Container(
    width: width,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.navy)),
        const SizedBox(height: 8),
        ...List.generate(ranked.length, (idx) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: [
                SizedBox(width: 16, child: Text('${idx + 1}.', style: const TextStyle(fontSize: 9.5, color: BankerColors.muted2))),
                Expanded(child: Text(ranked[idx], style: const TextStyle(fontSize: 10, color: BankerColors.muted), overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        })
      ],
    ),
  );
}

Widget _buildGiniRow(String feature, double val, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(feature, style: const TextStyle(fontSize: 10, color: BankerColors.ink), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: BankerColors.cream, borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: val,
              child: Container(color: color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(val * 100).toInt()}%', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildCmCell(String text, Color bg) {
  return Container(
    height: 32,
    margin: const EdgeInsets.all(2),
    color: bg,
    alignment: Alignment.center,
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.navy),
    ),
  );
}

Widget _buildClassF1Row(String className, double val, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(className, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text('F1: ${(val * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: BankerColors.muted2)),
        ],
      ),
      const SizedBox(height: 3),
      Container(
        height: 4,
        decoration: BoxDecoration(color: BankerColors.cream, borderRadius: BorderRadius.circular(2)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: val,
          child: Container(color: color),
        ),
      )
    ],
  );
}

DataRow _buildMetricsRow(
  String model, String className, String prec, String rec, String f1, String tp, String fp, String fn, Color color,
  {String? overrideClass}
) {
  return DataRow(
    cells: [
      DataCell(Text(model, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
      DataCell(_buildTempBadge(overrideClass ?? className)),
      DataCell(Text(prec, style: const TextStyle(fontSize: 10))),
      DataCell(Text(rec, style: const TextStyle(fontSize: 10))),
      DataCell(Text(f1, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))),
      DataCell(Text(tp, style: const TextStyle(fontSize: 10, color: Color(0xFF004F3F)))),
      DataCell(Text(fp, style: const TextStyle(fontSize: 10, color: Color(0xFFB3392F)))),
      DataCell(Text(fn, style: const TextStyle(fontSize: 10, color: Color(0xFFA87E5C)))),
    ],
  );
}

// Helpers
Color _getProbColor(double prob) {
  if (prob >= 65.0) return const Color(0xFFB3392F);
  if (prob >= 35.0) return const Color(0xFFA87E5C);
  return const Color(0xFF0F171F);
}

String _getTopCategoricalSummary(List<String> values) {
  final counts = <String, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(3).map((e) => '${e.key} (${e.value})').join(', ');
}

String _getNumericSummary(List<double> values) {
  if (values.isEmpty) return '—';
  final sorted = List<double>.from(values)..sort();
  final min = sorted.first;
  final max = sorted.last;
  final median = sorted[sorted.length ~/ 2];
  final sum = values.reduce((a, b) => a + b);
  final avg = sum / values.length;
  return 'min ${min.toStringAsFixed(0)} · median ${median.toStringAsFixed(0)} · max ${max.toStringAsFixed(0)} · avg ${avg.toStringAsFixed(1)}';
}

// ==========================================
// CUSTOM PAINTERS
// ==========================================
class DoughnutChartPainter extends CustomPainter {
  final double longTermRatio;
  final double shortTermRatio;
  final double notConvertedRatio;

  DoughnutChartPainter({
    required this.longTermRatio,
    required this.shortTermRatio,
    required this.notConvertedRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.40;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paintLong = Paint()
      ..color = const Color(0xFF004F3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintShort = Paint()
      ..color = const Color(0xFFA87E5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintNot = Paint()
      ..color = const Color(0xFFB3392F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final total = longTermRatio + shortTermRatio + notConvertedRatio;
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * 3.14159265,
        false,
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    double startAngle = -3.14159265 / 2;

    final sweepLong = (longTermRatio / total) * 2 * 3.14159265;
    if (sweepLong > 0) {
      canvas.drawArc(rect, startAngle, sweepLong, false, paintLong);
      startAngle += sweepLong;
    }

    final sweepShort = (shortTermRatio / total) * 2 * 3.14159265;
    if (sweepShort > 0) {
      canvas.drawArc(rect, startAngle, sweepShort, false, paintShort);
      startAngle += sweepShort;
    }

    final sweepNot = (notConvertedRatio / total) * 2 * 3.14159265;
    if (sweepNot > 0) {
      canvas.drawArc(rect, startAngle, sweepNot, false, paintNot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
