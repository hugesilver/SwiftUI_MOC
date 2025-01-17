//
//  SignupView.swift
//  MOC
//
//  Created by 김태은 on 1/24/24.
//

import SwiftUI
import PhotosUI

struct SignupView: View {
    @State private var isLoading: Bool = false
    
    @State var selectImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var nickname: String = ""
    
    @State private var isDone: Bool = false
    
    @StateObject var viewModel: UserInfoViewModel
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // 인사말
                        Text("가입을 환영합니다!\n프로필을 설정해봐요!")
                            .font(
                                .custom("Pretendard", size: 24)
                                .weight(.bold)
                            )
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("MOCTextColor"))
                            .padding(.bottom, 80)
                        
                        // 프로필 사진 선택
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Group {
                                if selectImage != nil {
                                    Image(uiImage: selectImage!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    if viewModel.userInfo?.profile_image != nil && viewModel.userInfo?.profile_image != "" {
                                        AsyncImage(url: URL(string: viewModel.userInfo!.profile_image)) {
                                            image in image.resizable()
                                        } placeholder: {
                                            Color("MOCDarkGray")
                                        }
                                        .aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle()
                                            .foregroundColor(Color("MOCDarkGray"))
                                    }
                                }
                            }
                            .clipShape(Circle())
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .stroke(Color("MOCDarkGray"), lineWidth: 1)
                            )
                            .overlay(IconCamera(), alignment: .bottomTrailing)
                        }
                        .onChange(of: photosPickerItem) { image, _ in
                            Task {
                                guard let data = try? await image?.loadTransferable(type: Data.self) else { return }
                                selectImage = UIImage(data: data)
                            }
                            
                            photosPickerItem = nil
                        }
                        .padding(.bottom, 80)
                        
                        // 닉네임 작성란
                        TextField("", text: $nickname, prompt: Text("닉네임을 입력하세요.").foregroundColor(Color("MOCLightGray")))
                            .background(Color("MOCBackground")).font(
                                .custom("Pretendard", size: 21)
                                .weight(.medium)
                            )
                            .foregroundColor(Color("MOCTextColor"))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 9)
                            .overlay(
                                Rectangle()
                                    .foregroundColor(Color("MOCTextColor"))
                                    .frame(height: 2)
                                , alignment: .bottom
                            )
                            .onChange(of: nickname) { _, _ in
                                nickname = String(nickname.prefix(8))
                            }
                        
                        Rectangle()
                            .fill(.clear)
                            .frame(height: 50)
                        
                        Spacer()
                        
                        // padding bottom 70 고정 버튼
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isLoading ? Color("MOCLightGray") : Color("MOCYellow"))
                            .stroke(isLoading ? Color("MOCLightGray") : Color("MOCYellow"), lineWidth: 1)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .overlay(
                                Text("다음")
                                    .font(
                                        .custom("Pretendard", size: 20)
                                        .weight(.bold)
                                    )
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color("MOCTextColor"))
                            )
                            .padding(.bottom, 70)
                            .onTapGesture {
                                if !isLoading {
                                    isLoading = true
                                    Task {
                                        let uploadTask = await viewModel.uploadUserData(nickname: nickname, profileImage: selectImage)
                                        if uploadTask {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                isDone = true
                                            }
                                        }
                                    }
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .padding(.horizontal, 50)
                    .background(Color("MOCBackground"))
                    .ignoresSafeArea(.keyboard)
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
            }
            
            // 프로필 업데이트 처리 중 화면
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.7))
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            switch viewModel.activeAlert {
            case .isNicknameEmpty: return
                Alert(title: Text("오류"), message: Text("닉네임을 입력하세요."), dismissButton: .default(Text("확인")))
                
            case .isNicknameNotAllowed: return
                Alert(title: Text("오류"), message: Text("닉네임은 한글, 영문자, 숫자만 입력해주세요."), dismissButton: .default(Text("확인")))
                
            case .isNicknameExist: return
                Alert(title: Text("알림"), message: Text("이미 존재하는 닉네임입니다."), dismissButton: .default(Text("확인")))
                
            case .isError: return
                Alert(title: Text("오류"), message: Text("오류가 발생하였습니다."), dismissButton: .default(Text("확인")))
            }
        }
        .onAppear {
            if viewModel.user != nil {
                Task {
                    await viewModel.getUserDocument(uid: viewModel.user!.uid)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isDone, destination: {
            ChatListView()
        })
    }
}

//#Preview {
//    SignupView()
//}
