//
//  MapView.swift
//  MyMap
//
//  Created by 赤荻大輝 on 2023/01/20.
//

import SwiftUI
import MapKit

enum MapType {
    case standard       //標準
    case satellite       //衛生写真
    case hydrid         //衛生写真+交通期間ラベル
}

struct UIMapView: UIViewRepresentable {
    // 検索キーワード
    let searchKey1: String
    let searchKey2: String
    //　マップ種類
    let mapType: MapType
    
    let Manager = MapManager()
    
    //表示する　View　を作成するときに実行
    func makeUIView(context: Context) -> UIViewType {
        let mapView = Manager.mapViewObj
    }// makeUIView　ここまで
    
    
    //表示した　View が更新されるたびに実行
    func updateUIView(_ uiView: MKMapView, context: Context){
        
        //　入力された文字をデバックエリアに表示
        print("検索キーワード:\(searchKey1)")
        print("検索キーワード:\(searchKey2)")
        //　マップ種類の設定
        switch mapType {
        case .standard:
            
            //　標準
            uiView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
            
        case .satellite:
            // 衛生写真
            uiView.preferredConfiguration =
            MKImageryMapConfiguration()
            
        case .hydrid:
            // 衛生写真+交通機関ラベル
            uiView.preferredConfiguration =
            MKHybridMapConfiguration()
        }
        
        //CLGeogoderインスタンスを生成
        let geocoder1 = CLGeocoder()
        let geocoder2 = CLGeocoder()
        
        let mapView = Manager.mapViewObj
        
        //入力された文字から位置情報を取得
        geocoder1.geocodeAddressString(
            searchKey1,
            completionHandler: { (placemarks, error) in
                
                //　リクエストの結果が存在し、１件目の位置情報から取り出す
                if let placemarks,
                   let firstPlacemark = placemarks.first,
                   let location = firstPlacemark.location {
                    
                    //　位置情報から緯度経度をtargetCoodinateに取り出す
                    let targetCoordinate1 = location.coordinate
                    
                    // 緯度経度をデバックエリアに表示
                    print("緯度経度： \(targetCoordinate1)")
                    
                    //　MKPointAnnotationインスタンスを生成し、ピンを作る
                    let pin1 = MKPointAnnotation()
                    
                    // ピンを置く場所に緯度経度を設定
                    pin1.coordinate = targetCoordinate1
                    
                    // ピンのタイトルを設定
                    pin1.title = searchKey1
                    
                    //　ピンを地図に置く
                    mapView.addAnnotation(pin1)
                    
                    
                    
                    geocoder2.geocodeAddressString(
                        searchKey2,
                        completionHandler: { (placemarks, error) in
                            
                            //　リクエストの結果が存在し、１件目の位置情報から取り出す
                            if let placemarks,
                               let firstPlacemark = placemarks.first,
                               let location = firstPlacemark.location {
                                
                                //　位置情報から緯度経度をtargetCoodinateに取り出す
                                let targetCoordinate2 = location.coordinate
                                
                                // 緯度経度をデバックエリアに表示
                                print("緯度経度： \(targetCoordinate2)")
                                
                                //　MKPointAnnotationインスタンスを生成し、ピンを作る
                                let pin2 = MKPointAnnotation()
                                
                                // ピンを置く場所に緯度経度を設定
                                pin2.coordinate = targetCoordinate2
                                
                                // ピンのタイトルを設定
                                pin2.title = searchKey2
                                
                                //　ピンを地図に置く
                                mapView.addAnnotation(pin2)
                                
                                
                                let basePlaceMark1 = MKPlacemark(coordinate: pin1.coordinate)
                                let basePlaceMark2 = MKPlacemark(coordinate: pin2.coordinate)
                                
                                let directionRequest = MKDirections.Request() // リクエストインスタンス
                                directionRequest.source = MKMapItem(placemark: basePlaceMark1) // 地点1登録
                                directionRequest.destination = MKMapItem(placemark: basePlaceMark2) // 地点2登録
                                directionRequest.transportType = MKDirectionsTransportType.automobile // 移動方法登録
                                
                                let directions = MKDirections(request: directionRequest)
                                directions.calculate { (response, error) in
                                    // オプショナルバインディングで取り出す
                                    guard let directionResonse = response else {
                                        if let error = error {
                                            print("発生したエラー内容：\(error.localizedDescription)")
                                        }
                                        return // nilなら処理を終了
                                    }
                                    
                                    // ルートを取得
                                    let route = directionResonse.routes[0]
                                    
                                    // ビューにオーバーレイオブジェクトを追加
                                    mapView.addOverlay(route.polyline, level: .aboveRoads)
                                    
                                    // 2地点間がちょうど表示される縮尺を取得
                                    let rect = route.polyline.boundingMapRect
                                    
                                    var rectRegion = MKCoordinateRegion(rect)
                                    rectRegion.span.latitudeDelta = rectRegion.span.latitudeDelta * 1.2
                                    rectRegion.span.longitudeDelta = rectRegion.span.longitudeDelta * 1.2
                                    mapView.setRegion(rectRegion, animated: true)
                                }
                                
                            }// if ここまで
                        })// geocoder ここまで
                }// if ここまで
            })// geocoder ここまで
        
    }// updateUIView ここまで
    return mapView
}// MapView ここまで

class MapManager:NSObject, MKMapViewDelegate{
    var mapViewObj = MKMapView()
    override init() {
        super.init() // スーパクラスのイニシャライザを実行
        mapViewObj.delegate = self // 自身をデリゲートプロパティに設定
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.orange
        renderer.lineWidth = 3.0
        return renderer
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        UIMapView(searchKey1: "羽田空港",searchKey2: "羽田", mapType: .standard)
    }
}
