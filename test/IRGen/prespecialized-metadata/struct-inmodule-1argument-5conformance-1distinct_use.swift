// RUN: %swift -prespecialize-generic-metadata -target %module-target-future -emit-ir %s | %FileCheck %s -DINT=i%target-ptrsize -DALIGNMENT=%target-alignment

// REQUIRES: OS=macosx || OS=ios || OS=tvos || OS=watchos || OS=linux-gnu
// UNSUPPORTED: CPU=i386 && OS=ios
// UNSUPPORTED: CPU=armv7 && OS=ios
// UNSUPPORTED: CPU=armv7s && OS=ios

// CHECK: @"$sytN" = external{{( dllimport)?}} global %swift.full_type

// CHECK: @"$s4main5ValueVySiGMf" = linkonce_odr hidden constant <{
// CHECK-SAME:    i8**,
// CHECK-SAME:    [[INT]],
// CHECK-SAME:    %swift.type_descriptor*,
// CHECK-SAME:    %swift.type*,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i32{{(, \[4 x i8\])?}},
// CHECk-SAME:    i64
// CHECK-SAME: }> <{
//                i8** @"$sB[[INT]]_WV",
//                i8** getelementptr inbounds (%swift.vwtable, %swift.vwtable* @"$s4main5ValueVySiGWV", i32 0, i32 0)
// CHECK-SAME:    [[INT]] 512,
// CHECK-SAME:    %swift.type_descriptor* bitcast ({{.+}}$s4main5ValueVMn{{.+}} to %swift.type_descriptor*),
// CHECK-SAME:    %swift.type* @"$sSiN",
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1PAAWP", i32 0, i32 0),
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1QAAWP", i32 0, i32 0),
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1RAAWP", i32 0, i32 0),
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1SAAWP", i32 0, i32 0),
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1TAAWP", i32 0, i32 0),
// CHECK-SAME:    i32 0{{(, \[4 x i8\] zeroinitializer)?}},
// CHECK-SAME:    i64 3
// CHECK-SAME: }>, align [[ALIGNMENT]]

protocol P {}
protocol Q {}
protocol R {}
protocol S {}
protocol T {}
extension Int : P {}
extension Int : Q {}
extension Int : R {}
extension Int : S {}
extension Int : T {}
struct Value<First : P & Q & R & S & T> {
  let first: First
}

@inline(never)
func consume<T>(_ t: T) {
  withExtendedLifetime(t) { t in
  }
}

// CHECK: define hidden swiftcc void @"$s4main4doityyF"() #{{[0-9]+}} {
// CHECK:   call swiftcc void @"$s4main7consumeyyxlF"(%swift.opaque* noalias nocapture %{{[0-9]+}}, %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, [[INT]], %swift.type_descriptor*, %swift.type*, i8**, i8**, i8**, i8**, i8**, i32{{(, \[4 x i8\])?}}, i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1))
// CHECK: }
func doit() {
  consume( Value(first: 13) )
}
doit()

// CHECK: ; Function Attrs: noinline nounwind
// CHECK: define hidden swiftcc %swift.metadata_response @"$s4main5ValueVMa"([[INT]] %0, i8** %1) #{{[0-9]+}} {
// CHECK: entry:
// CHECK:   [[ERASED_ARGUMENT_BUFFER:%[0-9]+]] = bitcast i8** %1 to i8*
// CHECK:   br label %[[TYPE_COMPARISON_1:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_1]]:
// CHECK:   [[ERASED_TYPE_ADDRESS:%[0-9]+]] = getelementptr i8*, i8** %1, i64 0
// CHECK:   %"load argument at index 0 from buffer" = load i8*, i8** [[ERASED_TYPE_ADDRESS]]
// CHECK:   [[EQUAL_TYPE:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSiN" to i8*), %"load argument at index 0 from buffer"
// CHECK:   [[EQUAL_TYPES:%[0-9]+]] = and i1 true, [[EQUAL_TYPE]]
// CHECK:   [[POINTER_TO_ERASED_TABLE_1:%[0-9]+]] = getelementptr i8*, i8** %1, i64 1
// CHECK:   [[ERASED_TABLE_1:%"load argument at index 1 from buffer"]] = load i8*, i8** [[POINTER_TO_ERASED_TABLE_1]], align 1
// CHECK:   [[UNERASED_TABLE_1:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_1]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_1:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_1]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_1:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_1]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_1:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(%swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_1]], %swift.protocol_conformance_descriptor* @"$sSi4main1PAAMc")
// CHECK:   [[EQUAL_ARGUMENTS_1:%[0-9]+]] = and i1 [[EQUAL_TYPES]], [[EQUAL_DESCRIPTORS_1]]
// CHECK:   [[POINTER_TO_ERASED_TABLE_2:%[0-9]+]] = getelementptr i8*, i8** %1, i64 2
// CHECK:   [[ERASED_TABLE_2:%"load argument at index 2 from buffer"]] = load i8*, i8** [[POINTER_TO_ERASED_TABLE_2]], align 1
// CHECK:   [[UNERASED_TABLE_2:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_2]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_2:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_2]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_2:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_2]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_2:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(%swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_2]], %swift.protocol_conformance_descriptor* @"$sSi4main1QAAMc")
// CHECK:   [[EQUAL_ARGUMENTS_2:%[0-9]+]] = and i1 [[EQUAL_ARGUMENTS_1]], [[EQUAL_DESCRIPTORS_2]]
// CHECK:   [[POINTER_TO_ERASED_TABLE_3:%[0-9]+]] = getelementptr i8*, i8** %1, i64 3
// CHECK:   [[ERASED_TABLE_3:%"load argument at index 3 from buffer"]] = load i8*, i8** [[POINTER_TO_ERASED_TABLE_3]], align 1
// CHECK:   [[UNERASED_TABLE_3:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_3]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_3:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_3]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_3:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_3]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_3:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(%swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_3]], %swift.protocol_conformance_descriptor* @"$sSi4main1RAAMc")
// CHECK:   [[EQUAL_ARGUMENTS_3:%[0-9]+]] = and i1 [[EQUAL_ARGUMENTS_2]], [[EQUAL_DESCRIPTORS_3]]
// CHECK:   [[POINTER_TO_ERASED_TABLE_4:%[0-9]+]] = getelementptr i8*, i8** %1, i64 4
// CHECK:   [[ERASED_TABLE_4:%"load argument at index 4 from buffer"]] = load i8*, i8** [[POINTER_TO_ERASED_TABLE_4]], align 1
// CHECK:   [[UNERASED_TABLE_4:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_4]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_4:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_4]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_4:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_4]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_4:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(%swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_4]], %swift.protocol_conformance_descriptor* @"$sSi4main1SAAMc")
// CHECK:   [[EQUAL_ARGUMENTS_4:%[0-9]+]] = and i1 [[EQUAL_ARGUMENTS_3]], [[EQUAL_DESCRIPTORS_4]]
// CHECK:   [[POINTER_TO_ERASED_TABLE_5:%[0-9]+]] = getelementptr i8*, i8** %1, i64 5
// CHECK:   [[ERASED_TABLE_5:%"load argument at index 5 from buffer"]] = load i8*, i8** [[POINTER_TO_ERASED_TABLE_5]], align 1
// CHECK:   [[UNERASED_TABLE_5:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_5]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_5:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_5]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_5:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_5]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_5:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(%swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_5]], %swift.protocol_conformance_descriptor* @"$sSi4main1TAAMc")
// CHECK:   [[EQUAL_ARGUMENTS_5:%[0-9]+]] = and i1 [[EQUAL_ARGUMENTS_4]], [[EQUAL_DESCRIPTORS_5]]
// CHECK:   br i1 [[EQUAL_ARGUMENTS_5]], label %[[EXIT_PRESPECIALIZED:[0-9]+]], label %[[EXIT_NORMAL:[0-9]+]]
// CHECK: [[EXIT_PRESPECIALIZED]]:
// CHECK:   ret %swift.metadata_response { %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, [[INT]], %swift.type_descriptor*, %swift.type*, i8**, i8**, i8**, i8**, i8**, i32{{(, \[4 x i8\])?}}, i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1), [[INT]] 0 }
// CHECK: [[EXIT_NORMAL]]:
// CHECK:   {{%[0-9]+}} = call swiftcc %swift.metadata_response @swift_getGenericMetadata([[INT]] %0, i8* [[ERASED_ARGUMENT_BUFFER]], %swift.type_descriptor* bitcast ({{.+}}$s4main5ValueVMn{{.+}} to %swift.type_descriptor*)) #{{[0-9]+}}
// CHECK:   ret %swift.metadata_response {{%[0-9]+}}
// CHECK: }
