import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class GuestRunDetailPage extends StatelessWidget {
  const GuestRunDetailPage({super.key, required this.run});

  final GuestRunModel run;

  static const int _flexLeft = 30;
  static const int _flexRight = 70;
  static const double _spaceBetweenColumns = 11.0;
  static const double _spaceBetweenRows = 26.0;

  @override
  Widget build(BuildContext context) {
    final DateTime? startDt = run.eventStartDatetime;

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Text('Run Details', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Event image (with shadow) or large kennel logo as fallback
              if ((run.eventImage ?? '').isNotEmpty &&
                  run.eventImage!.startsWith('http'))
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withAlpha(128),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: CachedNetworkImage(imageUrl: run.eventImage!),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: KennelLogo(
                    kennelLogoUrl: run.kennelLogo,
                    kennelShortName: run.kennelShortName ?? run.kennelName,
                    logoHeight: 200,
                    zoomGesture: KennelLogoZoomGesture.none,
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: FancyDivider(
                  key: Key('grd_div1'),
                  innerColor: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 25,
                  left: 20,
                  right: 20,
                  bottom: 10,
                ),
                child: AutoSizeText(
                  run.eventName,
                  style: ts_titleLarge,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
                child: FancyDivider(
                  key: Key('grd_div2'),
                  innerColor: Colors.white,
                ),
              ),
              Text('Event details', style: ts_headingLarge),
              const SizedBox(height: 15.0),
              TextScaleFactorClamper(
                textScaleFactor: deviceInfo.textClamp50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _row('Kennel:', run.kennelName),
                    if (run.isCountedRun &&
                        run.eventNumber != null &&
                        run.eventNumber! > 0)
                      _row('Run #:', '${run.eventNumber}'),
                    if (startDt != null)
                      _row(
                        'Date:',
                        DateFormat('E, MMM d, yyyy').format(startDt),
                      ),
                    if (startDt != null)
                      _row('Time:', DateFormat('h:mm a').format(startDt)),
                    if ((run.locationOneLineDesc ?? '').isNotEmpty)
                      _multiRow('Place:', run.locationOneLineDesc!),
                    if ((run.eventTypeName ?? '').isNotEmpty)
                      _row('Event:', run.eventTypeName!),
                    if ((run.eventPriceForMembers ?? 0) > 0)
                      _row(
                        'Run fees:',
                        '${run.eventCurrencyType ?? ''} ${_formatPrice(run.eventPriceForMembers!)} (members)',
                      ),
                    if ((run.eventPriceForNonMembers ?? 0) > 0)
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: _flexLeft,
                            child: Text(
                              '',
                              style: ts_listLabelStyle,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(
                            height: 0,
                            width: _spaceBetweenColumns,
                          ),
                          Expanded(
                            flex: _flexRight,
                            child: Text(
                              '${run.eventCurrencyType ?? ''} ${_formatPrice(run.eventPriceForNonMembers!)} (non-members)',
                              style: ts_listValueStyle,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if ((run.hares ?? '').isNotEmpty) _row('Hares:', run.hares!),
                    if ((run.locationStreet ?? '').isNotEmpty)
                      _multiRow('Street:', run.locationStreet!.trim()),
                    if ((run.locationPostCode ?? '').isNotEmpty)
                      _row('Post Code:', run.locationPostCode!),
                    if ((run.locationCity ?? '').isNotEmpty)
                      _row('City:', run.locationCity!),
                    if ((run.locationRegion ?? '').isNotEmpty)
                      _row('State:', run.locationRegion!),
                    if ((run.locationCountry ?? '').isNotEmpty)
                      _row('Country:', run.locationCountry!),
                  ],
                ),
              ),
              FancyDivider(
                key: UniqueKey(),
                innerColor: Colors.white,
                topMargin: 30.0,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(
                    'Share ${run.kennelShortName ?? run.kennelName} Runs',
                    style: ts_button,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if ((run.eventDescription ?? '').isNotEmpty) ...<Widget>[
                FancyDivider(
                  key: UniqueKey(),
                  innerColor: Colors.white,
                  topMargin: 30.0,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    run.eventDescription!,
                    style: ts_body.copyWith(height: 1.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GuestActionBar(),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: _flexLeft,
          child: Text(
            label,
            style: ts_listLabelStyle,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(
          height: _spaceBetweenRows,
          width: _spaceBetweenColumns,
        ),
        Expanded(
          flex: _flexRight,
          child: Text(
            value,
            style: ts_listValueStyle,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _multiRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: _flexLeft,
          child: Text(
            label,
            style: ts_listLabelStyle,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(
          height: _spaceBetweenRows,
          width: _spaceBetweenColumns,
        ),
        Expanded(
          flex: _flexRight,
          child: Text(
            value,
            style: ts_listValueStyle,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return price.truncateToDouble() == price
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
  }
}
