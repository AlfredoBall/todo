using System;
using System.Collections.Generic;
using System.Text;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Todo.Data.Access;
using C = Todo.Data.Entity.Context;
using E = Todo.Data.Entity;

namespace Todo.Data.Service;

public class ClipboardService(IMapper mapper)
{
    private readonly Guid demoUserID = new Guid("52515368-4ad4-4bae-9319-6886c234ee5a");

    public async Task<IList<Clipboard>> GetClipboards(C context, Guid userID)
    {
        return await context.Clipboards
            .Where(c => c.UserID == userID || c.UserID == demoUserID)
            .Select(i => mapper.Map<Clipboard>(i))
            .ToListAsync();
    }

    public async Task<Clipboard?> AddClipboard(C context, string name, Guid userID)
    {
        if (name.Trim().Length == 0 || await context.Clipboards.AnyAsync(c => c.Name == name && c.UserID == userID))
        {
            throw new ArgumentException("Invalid clipboard name or clipboard already exists.");
        }

        var entity = new E.Clipboard { Name = name, UserID = userID };
        await context.Clipboards.AddAsync(entity);
        await context.SaveChangesAsync();

        var addedEntity = await context.Clipboards
            .AsNoTracking()
            .SingleAsync(i => i.Name == name);

        return mapper.Map<Clipboard>(addedEntity);
    }

    public async Task<Clipboard> DeleteClipboard(C context, int clipboardID, Guid userID)
    {
        var entity = await context.Clipboards.SingleOrDefaultAsync(c => c.ID == clipboardID);

        if (entity == null || entity.UserID != userID)
        {
            throw new Exception("Clipboard not found or you do not have access to delete this clipboard.");
        }

        context.Clipboards.Remove(entity);
        await context.SaveChangesAsync();
        return mapper.Map<Clipboard>(entity);
    }

    public async Task<Clipboard> EditClipboard(C context, int clipboardID, string name, Guid userID)
    {
        if (name.Trim().Length == 0 || await context.Clipboards.AnyAsync(i => i.Name == name && i.UserID == userID))
        {
            throw new Exception("Invalid clipboard name or clipboard already exists.");
        }

        var clipboard = await context.Clipboards.SingleOrDefaultAsync(c => c.ID == clipboardID && c.UserID == userID);
        if (clipboard == null)
        {
            throw new Exception("Clipboard not found or you do not have access to edit this clipboard.");
        }

        clipboard.Name = name;
        await context.SaveChangesAsync();
        return mapper.Map<Clipboard>(clipboard);
    }
}
