import http from '@ohos.net.http';

interface GeneratedTypeLiteralInterface_1 {
  latitude: number;
  longitude: number;
}

interface GeneratedTypeLiteralInterface_2 {
  latitude: number;
  longitude: number;
  elevation: number;
}

export class ElevationService {
  // 使用Open-Elevation服务
  public async getElevation(latitude: number, longitude: number): Promise<number> {
    try {
      const httpRequest = http.createHttp();
      const url = `https://api.open-elevation.com/api/v1/lookup?locations=${latitude},${longitude}`;

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 60000,
        readTimeout: 60000
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as Map<string, GeneratedTypeLiteralInterface_2>
        if (result['results'] && result['results'].length > 0) {
          return result['results'][0].elevation;
        }
      }
      return 0;
    } catch (error) {
      console.error(`获取高程数据失败: ${error.message}`);
      return 0;
    }
  }

  // 批量获取多个点的高程
  // async getElevations(points: Array<GeneratedTypeLiteralInterface_1>): Promise<Array<number | null>> {
  //   try {
  //     const locations = points.map(p => `${p.latitude},${p.longitude}`).join('|');
  //     const httpRequest = http.createHttp();
  //     const url = `https://api.open-elevation.com/api/v1/lookup?locations=${locations}`;
  //
  //     const response = await httpRequest.request(url, {
  //       method: http.RequestMethod.GET,
  //       connectTimeout: 60000,
  //       readTimeout: 60000
  //     });
  //
  //     if (response.responseCode === 200) {
  //       const result = JSON.parse(response.result as string);
  //       return result.results.map((item: any) => item.elevation);
  //     }
  //     return points.map(() => null);
  //   } catch (error) {
  //     console.error(`批量获取高程数据失败: ${error.message}`);
  //     return points.map(() => null);
  //   }
  // }
}