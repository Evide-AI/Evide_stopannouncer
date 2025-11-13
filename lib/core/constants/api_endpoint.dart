class ApiEndpoint{
    static String getTripsByBusId({required int busId, int pageNo = 1}) => "/api/trips?bus_id=$busId&page=$pageNo&limit=10";
    static String getTripTimeLineData({required int tripId}) => "/api/trips/$tripId";
}
