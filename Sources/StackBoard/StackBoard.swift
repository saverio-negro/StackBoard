//
//  StackBoard.swift
//
//  Created by Saverio Negro on 7/13/25.
//

import SwiftUI

// MARK: - `AnyBlock`

// Define Type-Erased box to wrap each `View` object
// Avoid argument-type conflict to a single generic type parameter `T` upon generic inference.
public struct AnyBlock: Identifiable, View {
    
    public let id: UUID = UUID()
    fileprivate let isSection: Bool
    fileprivate let source: (any StackBoardSectionSource)?
    private let view: AnyView
    
    public init<T: View>(_ wrapped: T) {
        
        if let source = wrapped as? any StackBoardSectionSource {
            self.source = source
            self.isSection = true
        } else {
            self.source = nil
            self.isSection = false
        }
        
        self.view = AnyView(wrapped)
    }
    
    public var body: some View {
        view
    }
}

// MARK: - `StackBoard`

public struct StackBoard: View {
    
    let blocks: [AnyBlock]
    
    public init(@StackBoardBuilder content: () -> [AnyBlock]) {
        self.blocks = content()
    }
    
    public var body: some View {
        VStack {
            VStack(spacing:1) {
                ForEach(blocks) { block in
                    if block.isSection {
                        block
                    } else {
                        VStack {
                            block
                                .padding(10)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.gray.opacity(0.05)
        )
    }
}

// MARK: - `StackBoardSection`

public struct StackBoardSection<Header: View, Footer: View>: View {
    
    public let blocks: [AnyBlock]
    public let header: Header
    public let footer: Footer
    
    public init(
        @StackBoardBuilder content: () -> [AnyBlock],
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer,
    ) {
        self.blocks = content()
        self.header = header()
        self.footer = footer()
    }
    
    public var body: some View {
        VStack {
            HStack {
                header
                    .padding(.leading, 15)
                    .padding(.top, 2)
                    .foregroundStyle(.gray)
                Spacer()
            }
            
            StackBoardSectionContent(blocks: blocks)
            
            footer
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 35)
    }
}

public extension StackBoardSection where Header == Text, Footer == EmptyView {
    init(
        _ title: String,
        @StackBoardBuilder content: () -> [AnyBlock]
    ) {
        self.blocks = content()
        self.header = Text(title)
        self.footer = EmptyView()
    }
}

protocol StackBoardSectionSource: View {
    func extractBlocks() -> [AnyBlock]?
}

extension StackBoardSection: StackBoardSectionSource {
    func extractBlocks() -> [AnyBlock]? {
        self.blocks
    }
}

// MARK: - `StackBoardSectionContent`

struct StackBoardSectionContent: View {
    
    private let blocks: [AnyBlock]
    private var filteredBlocks: [AnyBlock] {
        return filter(blocks: self.blocks)
    }
    
    init(blocks: [AnyBlock]) {
        self.blocks = blocks
    }
    
    // Depth-First Traversal over Tree of type-erased (`AnyBlock`) views
    private func filter(blocks: [AnyBlock]) -> [AnyBlock] {
        var flat = [AnyBlock]()
        
        for block in blocks {
            if let nestedBlocks = block.source?.extractBlocks() {
                flat.append(contentsOf: filter(blocks: nestedBlocks))
            } else {
                flat.append(block)
            }
        }
        
        return flat
    }
    
    var body: some View {
        VStack(spacing: 1) {
            
            ForEach(filteredBlocks) { block in
                
                VStack {
                    block
                        .padding(10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 2)
                )
            }
        }
    }
}

// MARK: - `StackBoardBuilder`

@resultBuilder
public struct StackBoardBuilder {
    public static func buildBlock(_ components: AnyBlock...) -> [AnyBlock] {
        components
    }
    
    @MainActor
    public static func buildExpression<T: View>(_ expression: T) -> AnyBlock {
        return AnyBlock(expression)
    }
}
