//
//  DataKeys.h
//  TO-DO
//
//  Created by Siegrain on 16/5/9.
//  Copyright © 2016年 com.siegrain. All rights reserved.
//

/**
 *  各类常量关键字等
 */
#ifndef SGAPIKeys_h
#define SGAPIKeys_h

/**
 * ================================ 各种服务的Key or Secrets
 */

/* 高德地图（请自行配置） */
static NSString * const kAmapKey = @"2c1c7fefd22f3274a9a209f651797d5e";

/* 七牛 */
static NSString *const kQiniuDomain = @"oyiw6pnl7.bkt.clouddn.com/";
static NSString *const kQiniuBucketName = @"todo-head-image";
static NSString *const kQiniuAK = @"AYj7Wcat_fR2Pkb6sAnYEqeYQxwlGxcJ8HNbikAI";
static NSString *const kQiniuSK = @"EZlVtu3nfiGIpHyE5w3PSvbSLkUlrZQ_mhMcEnQ4";

/* LeanCloud */
static NSString *const kLeanCloudAppID   = @"UdxeYwXEhhgkwG2tDiNRIxxv-gzGzoHsz";
static NSString *const kLeanCloudAppKey  = @"djAc29mEhj3QXSYuL1WpEaNI";

/* Privacy Policy URL */
static NSString *const kPrivacyPolicyUrl = @"https://github.com/liuchangjun9343/ToDo";

///* 高德地图（请自行配置） */
//static NSString * const kAmapKey = @"";
//
///* 七牛 */
//static NSString *const kQiniuDomain = @"http://oj1x4qt6d.bkt.clouddn.com/";
//static NSString *const kQiniuBucketName = @"to-do";
//static NSString *const kQiniuSK = @"rDEdMSp8QIa6yroBreM0XpQYMTkJmUYfx0lz4IN-";
//static NSString *const kQiniuAK = @"05fAHfwHezWboSVVyTWJV14Ae9NZWMxCrbs2QFlL";
//
///* LeanCloud */
//static NSString *const kLeanCloudAppID = @"DbN2mTGoaxedDtiXvnwgNMeA-gzGzoHsz";
//static NSString *const kLeanCloudAppKey = @"8aiYpob0b7KpW1xK5vDeYNXN";
//
///* Privacy Policy URL */
//static NSString *const kPrivacyPolicyUrl = @"http://siegrain.wang/post/to-do-privacy-policy";

/**
 * ================================ 其他
 */

/* LeanCloud获取服务器时间的API地址 */
static NSString* const kLeanCloudServerDateApiUrl = @"https://api.leancloud.cn/1.1/date";

#endif
