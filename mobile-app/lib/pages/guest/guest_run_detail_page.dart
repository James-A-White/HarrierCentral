import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:map_launcher/map_launcher.dart' as maps;

class GuestRunDetailPage extends StatefulWidget {
  const GuestRunDetailPage({super.key, required this.run});

  final GuestRunModel run;

  @override
  State<GuestRunDetailPage> createState() => _GuestRunDetailPageState();
}

class _GuestRunDetailPageState extends State<GuestRunDetailPage> {
  int _activeTab = 0; // 0 = Details, 1 = Map

  static const int _flexLeft = 30;
  static const int _flexRight = 70;
  static const double _spaceBetweenColumns = 11.0;
  static const double _spaceBetweenRows = 26.0;

  @override
  Widget build(BuildContext context) {
    final GuestRunModel run = widget.run;
    final DateTime? startDt = run.eventStartDatetime;

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Text('Run Details', style: ts_appBarTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _TabBar(
            activeTab: _activeTab,
            onTabSelected: (int i) => setState(() => _activeTab = i),
          ),
        ),
      ),
      body: _activeTab == 0
          ? _buildDetails(context, run, startDt)
          : _buildMap(context, run),
      bottomNavigationBar: const GuestActionBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // Details tab
  // ---------------------------------------------------------------------------

  Widget _buildDetails(
    BuildContext context,
    GuestRunModel run,
    DateTime? startDt,
  ) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
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
    );
  }

  // ---------------------------------------------------------------------------
  // Map tab
  // ---------------------------------------------------------------------------

  Widget _buildMap(BuildContext context, GuestRunModel run) {
    final double? lat = run.latitude;
    final double? lon = run.longitude;

    if (lat == null || lon == null) {
      return Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Center(
          child: Text(
            'No location available for this run.',
            style: ts_body.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final latlng.LatLng point = latlng.LatLng(lat, lon);

    return Stack(
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate:
                  'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              subdomains: const <String>['mt0', 'mt1', 'mt2', 'mt3'],
            ),
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  width: 120,
                  height: 120,
                  point: point,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 58.0),
                    child: Image.asset('images/icons/map_pin_foot.png'),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeAppBarBackground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.directions, color: Colors.white),
            label: Text('Get Directions', style: ts_button),
            onPressed: () => _openDirections(context, run, lat, lon),
          ),
        ),
      ],
    );
  }

  Future<void> _openDirections(
    BuildContext context,
    GuestRunModel run,
    double lat,
    double lon,
  ) async {
    final String title = run.eventName;
    final String address =
        (run.locationOneLineDesc ?? '').isNotEmpty
            ? run.locationOneLineDesc!
            : <String?>[run.locationCity, run.locationCountry]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ');

    await Utilities.openMapsSheet(
      context,
      title,
      maps.Coords(lat, lon),
      address,
      ValueNotifier<bool>(false),
    );
  }

  // ---------------------------------------------------------------------------
  // Row helpers
  // ---------------------------------------------------------------------------

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
        const SizedBox(height: _spaceBetweenRows, width: _spaceBetweenColumns),
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
        const SizedBox(height: _spaceBetweenRows, width: _spaceBetweenColumns),
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

// ---------------------------------------------------------------------------
// Tab bar
// ---------------------------------------------------------------------------

class _TabBar extends StatelessWidget {
  const _TabBar({required this.activeTab, required this.onTabSelected});

  final int activeTab;
  final ValueChanged<int> onTabSelected;

  static const List<String> _labels = <String>['Details', 'Map'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 44,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: activeTab == i ? hc_red : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        color: activeTab == i ? Colors.white : Colors.black87,
                        fontWeight: activeTab == i
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
