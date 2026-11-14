/**
 * 后端服务地址集中配置（单一数据源）。
 *
 * NeuShare 鸿蒙端与 Web 端共用同一套后端 API，地址只需在这一处修改即可全局生效，
 * 避免在 HttpClient / AuthStore / 各页面里散落硬编码。
 *
 * 根据运行场景修改 BASE_URL（三选一）：
 *   1. 本地模拟器（DevEco 默认）：http://10.0.2.2:8080
 *      （10.0.2.2 是模拟器访问宿主机 localhost 的保留地址）
 *   2. 真机调试（手机与电脑同一局域网）：改成电脑的局域网 IP，
 *      例如 http://192.168.1.100:8080；同时确保后端启动时
 *      server.address=0.0.0.0，并放行电脑防火墙 8080 端口。
 *   3. 线上部署：改成后端域名，例如 https://api.neushare.example.com
 *      （注意需要 HTTPS，并在 module.json5 里配置对应域名的网络白名单）。
 */

// 后端 API 根地址（不含 /api，调用方会自行拼接路径）
export const BASE_URL: string = 'http://10.0.2.2:8080';

// 上传文件静态资源根地址：后端把 uploads 目录映射为 /files/**
export const FILE_BASE_URL: string = BASE_URL + '/files/';
